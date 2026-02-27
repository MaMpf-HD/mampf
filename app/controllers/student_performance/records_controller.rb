module StudentPerformance
  class RecordsController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
    before_action :set_record, only: :show

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      scope = @lecture.student_performance_records
                      .includes(:user)
                      .order(:computed_at)

      if params[:tutorial_id].present?
        user_ids = TutorialMembership
                   .where(tutorial_id: params[:tutorial_id])
                   .select(:user_id)
        scope = scope.where(user_id: user_ids)
      end

      @pagy, @records = pagy(scope)
      load_assessment_statuses
    end

    def show
      load_show_data
    end

    def recompute
      user_id = params[:user_id].presence

      if user_id
        PerformanceRecordUpdateJob.perform_async(@lecture.id, user_id.to_i)
      else
        PerformanceRecordUpdateJob.perform_async(@lecture.id)
      end

      respond_to do |format|
        format.turbo_stream do
          msg = if user_id
            I18n.t("student_performance.records.recompute.single")
          else
            I18n.t("student_performance.records.recompute.all")
          end
          flash.now[:notice] = msg
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
            if p.status == "pending" && p.submitted_at.nil?
              :not_submitted
            elsif p.status == "pending"
              :pending_grading
            else
              p.status.to_sym
            end
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
