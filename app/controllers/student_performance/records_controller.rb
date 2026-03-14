module StudentPerformance
  # Controller for managing student performance records, including listing,
  # showing details, and recomputing records.
  class RecordsController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
    before_action :set_record, only: :show

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    RECOMPUTE_THROTTLE = 30.seconds

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      scope = @lecture.student_performance_records
                      .includes(:user)
                      .joins(:user)
                      .order(Arel.sql(
                               "COALESCE(NULLIF(users.name_in_tutorials, " \
                               "''), users.name) ASC"
                             ))

      if params[:tutorial_id].present?
        user_ids = TutorialMembership
                   .where(tutorial_id: params[:tutorial_id])
                   .select(:user_id)
        scope = scope.where(user_id: user_ids)
      end

      @pagy, @records = pagy(scope)
      load_assessment_statuses
      @standard_max = @assessments.sum(&:effective_total_points)
      @achievements = @lecture.achievements.order(:title)
    end

    def show
      load_show_data
    end

    def recompute
      user_id = params[:user_id].presence

      if user_id
        recompute_single(user_id.to_i)
      else
        recompute_all
      end
    end

    def recompute_status
      scope = @lecture.student_performance_records
      record_count = scope.count
      null_count = scope.where(computed_at: nil).count
      has_null = null_count.positive?
      oldest = scope.minimum(:computed_at)
      threshold = (Time.zone.parse(params[:since]) if params[:since].present?)
      member_count = @lecture.members.count
      has_members = member_count.positive?
      done = threshold.present? &&
             ((!has_members && record_count.zero?) ||
              (has_members &&
               record_count >= member_count &&
               !has_null && oldest.present? && oldest > threshold))

      render json: { done: done }
    rescue ArgumentError
      render json: { done: false }
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path,
                    alert: I18n.t("student_performance.errors.no_lecture")
      end

      def set_record
        @record = @lecture.student_performance_records.find_by(id: params[:id])
        return if @record

        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.errors.no_record")
      end

      def authorize_lecture
        authorize!(:edit, @lecture)
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end

      def recompute_single(user_id)
        user = @lecture.members.find_by(id: user_id)

        unless user
          redirect_to lecture_student_performance_records_path(@lecture),
                      alert: I18n.t("student_performance.errors.no_member")
          return
        end

        service = StudentPerformance::ComputationService.new(lecture: @lecture)
        service.compute_and_upsert_record_for(user)

        record = @lecture.student_performance_records
                         .find_by(user_id: user_id)

        redirect_to lecture_student_performance_record_path(@lecture, record),
                    notice: I18n.t(
                      "student_performance.records.recompute.single"
                    )
      end

      def recompute_all
        cache_key = "recompute_all/lecture/#{@lecture.id}"

        unless Rails.cache.write(cache_key, true,
                                 expires_in: RECOMPUTE_THROTTLE,
                                 unless_exist: true)
          return respond_with_throttled
        end

        enqueue_time = Time.current
        set_recompute_poll_headers(queued: true, since: enqueue_time)

        PerformanceRecordUpdateJob.perform_async(
          @lecture.id,
          nil
        )

        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] =
              I18n.t("student_performance.records.recompute.all")
            render turbo_stream: stream_flash
          end
          format.html do
            redirect_to lecture_student_performance_records_path(@lecture),
                        notice: I18n.t(
                          "student_performance.records.recompute.all"
                        )
          end
        end
      end

      def respond_with_throttled
        msg = I18n.t("student_performance.records.recompute.throttled")
        set_recompute_poll_headers(queued: false)

        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = msg
            render turbo_stream: stream_flash
          end
          format.html do
            redirect_to lecture_student_performance_records_path(@lecture),
                        alert: msg
          end
        end
      end

      def set_recompute_poll_headers(queued:, since: nil)
        response.set_header("X-Recompute-Queued", queued ? "1" : "0")
        return unless since

        response.set_header("X-Recompute-Since", since.iso8601(6))
      end

      def load_show_data
        @assessments = Assessment::Assessment
                       .where(lecture_id: @lecture.id, assessable_type: "Assignment")
                       .includes(:tasks)
                       .joins("JOIN assignments ON assignments.id = " \
                              "assessment_assessments.assessable_id")
                       .order("assignments.deadline ASC")

        participations = Assessment::Participation
                         .where(assessment_id: @assessments.select(:id),
                                user_id: @record.user_id)
                         .select(:id, :assessment_id, :status, :submitted_at)

        @participation_by_assessment = participations.index_by(&:assessment_id)

        participation_ids = participations.select(&:reviewed?).map(&:id)
        task_point_sums = if participation_ids.any?
          Assessment::TaskPoint
            .where(assessment_participation_id: participation_ids)
            .group(:assessment_participation_id)
            .sum(:points)
        else
          {}
        end

        @points_by_assessment = {}
        participations.each do |p|
          @points_by_assessment[p.assessment_id] =
            p.reviewed? ? (task_point_sums[p.id] || 0) : nil
        end

        assignment_ids = @assessments.map(&:assessable_id)
        @submission_by_assignment = Submission
                                    .joins(:user_submission_joins)
                                    .where(user_submission_joins: { user_id: @record.user_id },
                                           assignment_id: assignment_ids)
                                    .index_by(&:assignment_id)
      end

      def load_assessment_statuses
        @assessments = Assessment::Assessment
                       .where(lecture_id: @lecture.id,
                              assessable_type: "Assignment")
                       .includes(:tasks)
                       .joins("JOIN assignments ON assignments.id = " \
                              "assessment_assessments.assessable_id")
                       .order("assignments.deadline ASC")

        user_ids = @records.map(&:user_id)
        return if user_ids.empty?

        participations = Assessment::Participation
                         .where(assessment_id: @assessments.select(:id),
                                user_id: user_ids)
                         .select(:id, :assessment_id, :user_id,
                                 :status, :submitted_at)

        @participation_map = {}
        participations.each do |p|
          @participation_map[[p.user_id, p.assessment_id]] =
            p.display_status
        end

        reviewed_ids = participations.select(&:reviewed?).map(&:id)
        task_point_sums = if reviewed_ids.any?
          Assessment::TaskPoint
            .where(assessment_participation_id: reviewed_ids)
            .group(:assessment_participation_id)
            .sum(:points)
        else
          {}
        end

        @points_map = {}
        participations.each do |p|
          next unless p.reviewed?

          @points_map[[p.user_id, p.assessment_id]] =
            task_point_sums[p.id] || 0
        end
      end
  end
end
