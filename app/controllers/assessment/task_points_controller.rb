module Assessment
  class TaskPointsController < ApplicationController
    include ExamStreams

    before_action :set_assessable_resource,
                  only: [:update_team_multi, :update_team,
                         :update_participation, :refresh_submission,
                         :refresh_participation, :mark_as_participated,
                         :remove_participated, :mark_as_absent, :remove_absent,
                         :mark_as_exempt, :remove_exempt]
    before_action :set_locale
    before_action :authorize_assessment!, only: [:update_team_multi,
                                                 :update_team,
                                                 :update_participation,
                                                 :refresh_submission,
                                                 :refresh_participation,
                                                 :remove_participated,
                                                 :mark_as_absent,
                                                 :remove_absent]
    # An exemption changes what counts for a candidate; that is the
    # lecturer's call, not the grader's.
    before_action :authorize_lecture_edit!, only: [:mark_as_exempt, :remove_exempt]
    before_action :refuse_without_row, only: [:update_participation, :refresh_participation]
    before_action :refuse_unless_sheet, only: [:mark_as_participated, :remove_participated]
    before_action :refuse_unless_exam, only: [:mark_as_absent, :remove_absent,
                                              :mark_as_exempt, :remove_exempt]
    before_action :refuse_unless_candidate, only: [:update_participation, :mark_as_absent,
                                                   :remove_absent, :mark_as_exempt,
                                                   :remove_exempt]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.errors.invalid_request_params"))
    end

    rescue_from SubmissionGraderService::SubmissionGraderError,
                PointEntryService::PointEntryError,
                AbsenceHandling::InvalidTransitionError do |e|
      respond_with_flash(:alert, e.message)
    end

    # Authorization uses the Submission or Participation tutorial, even when
    # points are entered from the lecture table. Bulk entries are authorized
    # separately by SubmissionGraderService.
    def authorize_assessment!
      authorize!(:enter_points, @tutorial || @lecture)
    end

    def authorize_lecture_edit!
      authorize!(:update, @lecture)
    end

    def update_team_multi
      unless @assessable.is_a?(Assignment)
        return respond_with_flash(:alert, t("assessment.errors.invalid_assessable_type"))
      end

      begin
        records = JSON.parse(params[:submissions] || "[]")
      rescue JSON::ParserError
        respond_with_flash(:alert, t("assessment.errors.invalid_request_params"))
        return
      end
      SubmissionGraderService.score_multi_teams_by_types!(records, current_user)

      rerender_submission_table
    end

    def update_team
      begin
        task_points = JSON.parse(params[:task_points] || "{}")
      rescue JSON::ParserError
        respond_with_flash(:alert, t("assessment.errors.invalid_request_params"))
        return
      end

      unless @assessable.is_a?(Assignment)
        return respond_with_flash(:alert, t("assessment.errors.invalid_assessable_type"))
      end

      ActiveRecord::Base.transaction do
        SubmissionGraderService.score_tasks_by_submission!(
          @submission, task_points, current_user
        )
      end
      @submission = @submission.reload
      @assessable = @submission.assignment
      @tutorial = @submission.tutorial
      render_task_points_update(
        turbo_stream.replace(
          "submission-row-#{@submission.id}",
          html: render_to_string(
            SubmissionRowComponent.new(
              submission: @submission,
              assignment: @assessable,
              grading_scope: table_scope
            )
          )
        )
      )
    end

    def update_participation
      begin
        task_points = JSON.parse(params[:task_points] || "{}")
      rescue JSON::ParserError
        respond_with_flash(:alert, t("assessment.errors.invalid_request_params"))
        return
      end

      ActiveRecord::Base.transaction do
        case @assessable
        when Exam then score_exam_tasks!(task_points)
        else
          SubmissionGraderService.score_tasks_by_participation!(
            @participation, task_points, current_user
          )
        end
      end

      @participation = @participation.reload
      render_task_points_update(participation_row_stream)
    end

    def refresh_submission
      rerender_submission_row
    end

    def refresh_participation
      @user = @participation.user
      rerender_user_row
    end

    def mark_as_absent
      AbsenceHandling.mark_absent(@participation)
      render_task_points_update(participation_row_stream)
    end

    def remove_absent
      AbsenceHandling.remove_absent(@participation)
      render_task_points_update(participation_row_stream)
    end

    def mark_as_exempt
      AbsenceHandling.mark_exempt(@participation, note: params[:note])
      render_task_points_update(participation_row_stream)
    end

    def remove_exempt
      AbsenceHandling.remove_exempt(@participation)
      render_task_points_update(participation_row_stream)
    end

    def mark_as_participated
      user = @lecture.members.find_by(id: params[:user_id])
      unless user
        return respond_with_flash(:alert, t("assessment.errors.user_not_found"),
                                  status: :not_found)
      end

      render turbo_stream: [record_paper_hand_in(user), summary_stream]
    end

    def remove_participated
      SubmissionGraderService.remove_participation(@participation)
      @participation.reload
      render turbo_stream: [participation_row_stream, summary_stream].flatten
    end

    private

      # grading_scope_type selects the table to update, not the permission scope;
      # a lecture table can contain participations from several tutorials.
      def table_scope
        (@tutorial if @grading_scope_type == "tutorial") || @lecture
      end

      def participation_row(participation = @participation)
        ParticipationRowComponent.new(participation: participation,
                                      assessment: @assessment,
                                      table_option: :pointing,
                                      grading_scope: table_scope)
      end

      # A participation belongs to the group that holds it, however the person
      # has moved since; only a new one goes to the group they sit in now.
      def record_paper_hand_in(user)
        roster_tutorial = user.rostered_tutorial_in(@lecture)
        row_before = @assessment.assessment_participations.find_by(user: user)
        scope = row_before ? row_before.tutorial : roster_tutorial
        authorize!(:enter_points, scope || @lecture)
        row_id = if row_before
          "pointing-participation-row-#{row_before.id}"
        else
          "pointing-participation-row-user-#{user.id}"
        end
        participation = SubmissionGraderService.init_participation(@assessment, user,
                                                                   roster_tutorial)
        turbo_stream.replace(row_id, html: render_to_string(participation_row(participation)))
      end

      # Points tables are drawn for sheets and exams; a participation in
      # anything else has no row to go back into.
      def refuse_without_row
        return if @assessable.is_a?(Assignment) || @assessable.is_a?(Exam)

        unsupported_assessable
      end

      # Only a sheet is handed in; only an exam is attended.
      def refuse_unless_sheet
        return if @assessable.is_a?(Assignment)

        unsupported_assessable
      end

      def refuse_unless_exam
        return if @assessable.is_a?(Exam)

        unsupported_assessable
      end

      def unsupported_assessable
        respond_with_flash(:alert, t("assessment.task_points.unsupported_assessment_type"),
                           status: :bad_request)
      end

      # The row of somebody taken off the roster stays in the database; nothing
      # is recorded on it any more.
      def refuse_unless_candidate
        return unless @assessable.is_a?(Exam)
        return if @assessable.users.exists?(id: @participation.user_id)

        respond_with_flash(:alert, t("assessment.grading_exam.user_not_candidate"))
      end

      def rerender_submission_row
        respond_to do |format|
          format.turbo_stream do
            row = turbo_stream.replace(
              "submission-row-#{@submission.id}",
              html: render_to_string(
                SubmissionRowComponent.new(
                  submission: @submission,
                  assignment: @assessable,
                  grading_scope: table_scope
                )
              )
            )
            render turbo_stream: [row, summary_stream]
          end
        end
      end

      def rerender_user_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [participation_row_stream, summary_stream].flatten
          end
        end
      end

      def participation_row_stream
        return exam_streams if @assessable.is_a?(Exam)

        turbo_stream.replace("pointing-participation-row-#{@participation.id}",
                             html: render_to_string(participation_row))
      end

      # An exam has nothing to hand in and no group: points go in unless the
      # candidate was absent or excused.
      def score_exam_tasks!(task_points)
        if @participation.absent? || @participation.exempt?
          status = t("assessment.grading_exam.status_word.#{@participation.status}")
          raise(PointEntryService::PointEntryError,
                t("assessment.grading_exam.not_scorable", status: status))
        end

        PointEntryService.enter_points(@participation, task_points, current_user)
      end

      def render_task_points_update(*streams)
        flash.now[:notice] = t("assessment.task_points.update")
        render turbo_stream: (streams + [summary_stream, stream_flash]).flatten.compact
      end

      # ExamStreams already includes the exam summaries.
      def summary_stream
        return [] if @assessable.is_a?(Exam)

        summary = TutorialPointingTableComponent.new(assignment: @assessable,
                                                     grading_scope: table_scope).summary
        turbo_stream.replace("pointing-summary", html: render_to_string(summary))
      end

      def rerender_submission_table
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "pointing-table",
              html: render_to_string(
                TutorialPointingTableComponent.new(
                  assignment: @assessable,
                  grading_scope: table_scope
                )
              )
            )
          end
        end
      end

      def set_assessable_resource
        @grading_scope_type = params[:grading_scope_type]
        if params[:submissions]
          set_resources_from_bulk_params_submissions
        elsif params[:submission_id]
          set_resources_from_submission
        elsif params[:assignment_id]
          set_resources_from_assignment
        elsif params[:participation_id]
          set_resources_from_participation
        end
      end

      # The lecture's table saves rows of every group and of people in none,
      # so it names no tutorial; the group's table names its own.
      def set_resources_from_bulk_params_submissions
        @assessable = Assignment.find_by(id: params["assignment_id"])
        unless @assessable
          return respond_with_flash(:alert, t("assessment.errors.no_assignment"),
                                    status: :not_found)
        end

        @lecture = @assessable.lecture
        if params["tutorial_id"].present?
          @tutorial = @lecture.tutorials.find_by(id: params["tutorial_id"])
          unless @tutorial
            return respond_with_flash(:alert, t("assessment.errors.no_tutorial"),
                                      status: :not_found)
          end
        end

        @assessment = @assessable.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"),
                           status: :not_found)
      end

      def set_resources_from_submission
        @submission = Submission.find_by(id: params[:submission_id])
        unless @submission
          return respond_with_flash(:alert, t("assessment.errors.no_submission"),
                                    status: :not_found)
        end

        @assessable = @submission.assignment
        @tutorial = @submission.tutorial
        @lecture = @tutorial.lecture

        @assessment = @assessable.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"),
                           status: :not_found)
      end

      # A Participation can have no tutorial, including for paper submissions.
      # Authorization then uses its assessment's lecture.
      def set_resources_from_participation
        @participation = Participation.find_by(id: params[:participation_id])
        unless @participation
          return respond_with_flash(:alert, t("assessment.errors.no_participation"),
                                    status: :not_found)
        end

        @assessment = @participation.assessment
        @lecture = @assessment.lecture
        @assessable = @assessment.assessable
        @tutorial = @participation.tutorial
        return if @assessable

        respond_with_flash(:alert, t("assessment.task_points.participation_missing_assignment"),
                           status: :not_found)
      end

      def set_resources_from_assignment
        @assessable = Assignment.find_by(id: params[:assignment_id])
        unless @assessable
          return respond_with_flash(:alert, t("assessment.errors.no_assignment"),
                                    status: :not_found)
        end

        @tutorial = Tutorial.find_by(id: params[:tutorial_id])
        @lecture = @assessable.lecture
        @assessment = @assessable.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"),
                           status: :not_found)
      end

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_locale
        I18n.locale = @lecture&.locale_with_inheritance ||
                      @assessable&.lecture&.locale_with_inheritance ||
                      @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
