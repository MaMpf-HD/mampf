module StudentPerformance
  # Controller for managing student performance records, including listing,
  # showing details, and recomputing records.
  class RecordsController < ApplicationController
    include StudentPerformance::LectureScoped

    # A lecture member without a tutorial cannot hand anything in, so they read
    # as 0 % — the filter is how staff find them, not a tutorial id.
    NO_TUTORIAL = "none".freeze

    before_action :set_record, only: :show

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      @due_points = due_points
      scope = filter_by_tutorial(filter_by_name(records_scope))

      @pagy, @records = pagy(sorted(scope))
      assessments = assignment_assessments
      # A sheet nobody could hand in yet counts towards none of the figures in
      # this table, so it gets no column of its own — the detail page lists it.
      # The heading says how many were left out.
      @assessments = assessments.select { |a| due_points.due?(a.id) }
      @not_due_count = assessments.size - @assessments.size
      load_assessment_statuses
      @awaiting_marking = awaiting_marking_counts(scope, assessments)
      @achievements = @lecture.achievements.order(:title)
    end

    def show
      @due_points = due_points
      load_show_data
    end

    def recompute
      user_id = params[:user_id].presence

      unless user_id
        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.errors.no_member")
        return
      end

      recompute_single(user_id.to_i)
    end

    private

      def records_scope
        @lecture.student_performance_records
                .includes(:user)
                .joins(:user)
                .order(Arel.sql(
                         "COALESCE(NULLIF(users.name_in_tutorials, " \
                         "''), users.name) ASC"
                       ))
      end

      def filter_by_tutorial(scope)
        return scope if params[:tutorial_id].blank?
        return scope.where.not(user_id: tutorial_member_ids) if no_tutorial?

        tutorial = @lecture.tutorials.find_by(id: params[:tutorial_id])
        return scope unless tutorial

        scope.where(user_id: TutorialMembership.where(tutorial: tutorial)
                                               .select(:user_id))
      end

      # The filter that asks for nobody's group rather than for a group.
      def no_tutorial?
        params[:tutorial_id] == NO_TUTORIAL
      end

      # The name is the order the database can give. The maximum and the
      # percentage are worked out per request from what the tutors have marked,
      # so those are ordered here and the page cut from the result - Pagy takes
      # an Array as readily as a relation.
      def sorted(scope)
        key = sort_key
        return scope unless key

        sign = params[:dir] == "desc" ? -1 : 1
        # The position is the tie-breaker, so equal numbers keep the order by
        # name the scope arrives in, whichever way round the column is sorted.
        scope.to_a.each_with_index
             .sort_by { |record, position| [sign * key.call(record), position] }
             .map(&:first)
      end

      # A student without a basis is not at 0 % but below it: she sorts with
      # the lowest, and never above someone who has actually scored nothing.
      def sort_key
        case params[:sort]
        when "points"
          ->(record) { record.points_total_materialized.to_f }
        when "maximum"
          ->(record) { due_points.marked_max_for(record.user_id).to_f }
        when "percentage"
          ->(record) { due_points.marked_percentage_for(record)&.to_f || -1 }
        end
      end

      def tutorial_member_ids
        TutorialMembership.where(tutorial: @lecture.tutorials).select(:user_id)
      end

      # Per assignment, how many of the listed students handed in without being
      # marked yet. Counted over the whole filtered set rather than the current
      # page, because the number describes the sheet, not the page.
      #
      # Only over sheets that are due: nobody may mark before the grace period
      # is over, so an early hand-in is waiting for the deadline, not for a
      # tutor, and counting it claims a backlog nobody could work off.
      def awaiting_marking_counts(scope, assessments)
        ids = assessments.select { |a| due_points.due?(a.id) }.map(&:id)
        return {} if ids.empty?

        Assessment::Participation
          .where(assessment_id: ids,
                 user_id: scope.reorder(nil).select(:user_id),
                 status: :pending)
          .where.not(submitted_at: nil)
          .group(:assessment_id)
          .count
      end

      def set_record
        @record = @lecture.student_performance_records.find_by(id: params[:id])
        return if @record

        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.errors.no_record")
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

      # Every sheet of the lecture, oldest deadline first.
      def assignment_assessments
        Assessment::Assessment
          .where(lecture_id: @lecture.id, assessable_type: "Assignment")
          .includes(:tasks)
          .joins("JOIN assignments ON assignments.id = " \
                 "assessment_assessments.assessable_id")
          .order("assignments.deadline ASC")
          .to_a
      end

      # The detail page is a list, not a grid: a sheet that is not due yet costs
      # a row rather than a column, and the badge writes out what it is.
      def load_show_data
        @assessments = assignment_assessments

        participations = Assessment::Participation
                         .where(assessment_id: @assessments.map(&:id),
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
        user_ids = @records.map(&:user_id)
        return if user_ids.empty?

        participations = Assessment::Participation
                         .where(assessment_id: @assessments.map(&:id),
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
