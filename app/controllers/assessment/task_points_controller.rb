module Assessment
  class TaskPointsController < ApplicationController
    before_action :set_assignment_resource,
                  only: [:update_team_multi, :update_team,
                         :update_participation, :refresh_submission,
                         :refresh_user, :mark_as_participated, :remove_participated]
    before_action :set_locale
    before_action :authorize_assessment!, only: [:update_team_multi,
                                                 :update_team,
                                                 :update_participation,
                                                 :refresh_submission,
                                                 :refresh_user,
                                                 :remove_participated]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.errors.invalid_request_params"))
    end

    rescue_from SubmissionGraderService::SubmissionGraderError,
                PointEntryService::PointEntryError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      if @grading_scope_type == "tutorial"
        authorize! :grade, @tutorial
      else
        authorize! :grade, @lecture
      end
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
              grading_scope:
                 @grading_scope_type == "tutorial" ? @tutorial : @lecture
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

      case @assessable
      when Assignment
        ActiveRecord::Base.transaction do
          SubmissionGraderService.score_tasks_by_participation!(
            @participation, task_points, current_user
          )
        end
        grading_scope = @grading_scope_type == "tutorial" ? @tutorial : @lecture
        save_url = point_user_tutorial_path(
          @participation,
          grading_scope_type: @grading_scope_type
        )
        refresh_url = refresh_point_user_tutorial_path(
          @participation,
          grading_scope_type: @grading_scope_type
        )

      when Exam
        return respond_with_flash(:alert, "exam_not_yet_supported")
      else
        return respond_with_flash(:alert, t("assessment.errors.invalid_assessable_type"))
      end

      @participation = @participation.reload
      @assessable = @participation.assessment&.assessable
      render_task_points_update(
        turbo_stream.replace(
          "participation-row-#{@participation.id}",
          html:
            render_to_string(
              ParticipationRowComponent.new(
                participation: @participation,
                assessment: @assessable.assessment,
                grading_scope: grading_scope,
                save_url: save_url,
                refresh_url: refresh_url
              )
            )
        )
      )
    end

    def refresh_submission
      rerender_submission_row
    end

    def refresh_user
      @user = @participation.user
      rerender_user_row
    end

    def mark_as_participated
      user = User.find_by(id: params[:user_id])
      return respond_with_flash(:alert, t("assessment.errors.user_not_found")) unless user

      roster_tutorial = user.rostered_tutorial_in(@lecture)
      unless roster_tutorial
        return respond_with_flash(:alert,
                                  t("assessment.task_points.user_not_rostered"))
      end

      authorize! :grade, roster_tutorial
      @tutorial = roster_tutorial
      SubmissionGraderService.init_participation(@assessment, user, @tutorial)
      rerender_submission_table
    end

    def remove_participated
      removed_participation = SubmissionGraderService.remove_participation(@participation)
      if removed_participation
        flash.now[:notice] =
          t("assessment.task_points.participation_removed")
      end
      rerender_submission_table
    end

    private

      def rerender_submission_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "submission-row-#{@submission.id}",
              html: render_to_string(
                SubmissionRowComponent.new(
                  submission: @submission,
                  assignment: @assessable,
                  grading_scope:
                     @grading_scope_type == "tutorial" ? @tutorial : @lecture
                )
              )
            )
          end
        end
      end

      def rerender_user_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "participation-row-#{@participation.id}",
              html: render_to_string(
                ParticipationRowComponent.new(
                  participation: @participation,
                  assessment: @assessable.assessment,
                  grading_scope:
                     @grading_scope_type == "tutorial" ? @tutorial : @lecture,
                  save_url:
                     point_user_tutorial_path(
                       @participation,
                       grading_scope_type: @grading_scope_type
                     ),
                  refresh_url:
                     refresh_point_user_tutorial_path(
                       @participation,
                       grading_scope_type: @grading_scope_type
                     )
                )
              )
            )
          end
        end
      end

      def render_task_points_update(*streams)
        flash.now[:notice] = t("assessment.task_points.update")
        render turbo_stream: streams.flatten.compact + [stream_flash].compact
      end

      def rerender_submission_table
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "grading-table",
              html: render_to_string(
                TutorialPointingTableComponent.new(
                  assignment: @assessable,
                  grading_scope: @grading_scope_type == "tutorial" ? @tutorial : @lecture
                )
              )
            )
          end
        end
      end

      def set_assignment_resource
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

      def set_resources_from_bulk_params_submissions
        @tutorial = Tutorial.find_by(id: params["tutorial_id"])
        @assessable = Assignment.find_by(id: params["assignment_id"])

        unless @tutorial
          return respond_with_flash(:alert,
                                    t("assessment.errors.no_tutorial"))
        end

        @lecture = @tutorial.lecture

        unless @assessable
          return respond_with_flash(:alert,
                                    t("assessment.errors.no_assignment"))
        end

        @assessment = @assessable.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"))
      end

      def set_resources_from_submission
        @submission = Submission.find_by(id: params[:submission_id])
        unless @submission
          return respond_with_flash(:alert,
                                    t("assessment.errors.no_submission"))
        end

        @assessable = @submission.assignment
        unless @assessable
          return respond_with_flash(:alert,
                                    t("assessment.task_points.submission_missing_assignment"))
        end

        @tutorial = @submission.tutorial
        unless @tutorial
          return respond_with_flash(:alert,
                                    t("assessment.task_points.submission_missing_tutorial"))
        end

        @lecture = @tutorial.lecture

        @assessment = @assessable.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"))
      end

      def set_resources_from_participation
        @participation = Participation.find_by(id: params[:participation_id])
        unless @participation
          return respond_with_flash(:alert,
                                    t("assessment.errors.no_participation"))
        end

        @assessment = @participation.assessment
        unless @assessment
          return respond_with_flash(:alert,
                                    t("assessment.task_points.participation_missing_assessment"))
        end

        @lecture = @assessment.lecture

        @assessable = @assessment.assessable
        unless @assessable
          return respond_with_flash(:alert,
                                    t("assessment.task_points.participation_missing_assignment"))
        end

        case @assessable
        when Assignment
          @tutorial = @participation.tutorial
          unless @tutorial
            respond_with_flash(:alert,
                               t("assessment.task_points.participation_missing_tutorial"))
          end
        when Exam
          respond_with_flash(:alert, "exam_not_yet_supported")
        else
          respond_with_flash(:alert, t("assessment.errors.invalid_assessable_type"))
        end
      end

      def set_resources_from_assignment
        @assessable = Assignment.find_by(id: params[:assignment_id])
        unless @assessable
          return respond_with_flash(:alert,
                                    t("assessment.errors.no_assignment"))
        end

        @tutorial = Tutorial.find_by(id: params[:tutorial_id])
        @lecture = @assessable.lecture
        @assessment = @assessable.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"))
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
