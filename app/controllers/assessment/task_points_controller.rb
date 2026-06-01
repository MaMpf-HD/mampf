module Assessment
  class TaskPointsController < ApplicationController
    before_action :set_assignment_resource,
                  only: [:update_team_multi, :update_team,
                         :update_user, :refresh_submission,
                         :refresh_user, :mark_as_participated]
    before_action :set_locale

    def update_team_multi
      case params[:type]
      when "Tutorial"
        records = JSON.parse(params[:submissions])
        records.each do |entry|
          if entry["target"] == "submission"
            submission = Submission.find(entry["id"])
            SubmissionGraderService.score_tasks_by_submission!(
              submission, entry["task_points"], current_user
            )
          end

          next unless entry["target"] == "user"

          user = User.find(entry["id"])
          SubmissionGraderService.score_tasks_by_user!(
            user, @assignment, entry["task_points"], current_user
          )
        end

        @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                            &.order(:last_modification_by_users_at)
        @non_submitters = @assignment.non_submitters(@tutorial)
        rerender_submission_table
      end
    end

    def update_team
      task_points = JSON.parse(params[:task_points] || "{}")
      case params[:type]
      when "Tutorial"
        SubmissionGraderService.score_tasks_by_submission!(
          @submission, task_points, current_user
        )
        @submission = @submission.reload
        @assignment = @submission.assignment
        @tutorial = @submission.tutorial
        render_task_points_update(
          turbo_stream.replace(
            "submission-row-#{@submission.id}",
            SubmissionRowComponent.new(
              submission: @submission,
              assignment: @assignment,
              tutorial: @tutorial
            )
          )
        )
      end
    end

    def update_user
      task_points = JSON.parse(params[:task_points] || "{}")
      case params[:type]
      when "Tutorial"
        SubmissionGraderService.score_tasks_by_participation!(
          @participation, task_points, current_user
        )
        @user = @participation.user
        render_task_points_update(
          turbo_stream.replace(
            "user-row-#{@user.id}",
            html: render_to_string(
              UserRowComponent.new(
                user: @user,
                assignment: @assignment,
                tutorial: @tutorial
              )
            )
          )
        )
      end
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
      SubmissionGraderService.init_participation(@assessment, user)
      @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                          &.order(:last_modification_by_users_at)
      @non_submitters = @assignment.non_submitters(@tutorial)
      rerender_submission_table
    end

    private

      def rerender_submission_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "submission-row-#{@submission.id}",
              SubmissionRowComponent.new(
                submission: @submission,
                assignment: @assignment,
                tutorial: @tutorial
              )
            )
          end
        end
      end

      def rerender_user_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "user-row-#{@user.id}",
              html: render_to_string(
                UserRowComponent.new(
                  user: @user,
                  assignment: @assignment,
                  tutorial: @tutorial
                )
              )
            )
          end
        end
      end

      def render_task_points_update(*streams)
        flash.now[:notice] = t("assessment.task_points.submission.message.update")
        render turbo_stream: streams.flatten.compact + [stream_flash].compact
      end

      def rerender_submission_table
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "grading-table",
              html: render_to_string(
                TutorialGradingTableComponent.new(
                  assignment: @assignment,
                  tutorial: @tutorial,
                  stack: @stack,
                  non_submitters: @non_submitters
                )
              )
            )
          end
        end
      end

      def set_assignment_resource
        if params[:submissions]
          @tutorial = Tutorial.find_by(id: params["tutorial_id"])
          @assignment = Assignment.find_by(id: params["assignment_id"])
          @assessment = @assignment.assessment
          return if @tutorial && @assignment && @assessment

          respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))

        elsif params[:submission_id]
          @submission = Submission.find_by(id: params[:submission_id])
          @assignment = @submission.assignment
          @assessment = @assignment.assessment
          @tutorial = @submission.tutorial
          return if @submission && @assignment && @assessment && @tutorial

          respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))

        elsif params[:participation_id]
          @participation = Participation.find_by(id: params[:participation_id])
          @assignment = @participation.assignment
          @assessment = @assignment.assessment
          @tutorial = @participation.tutorial

          return if @participation && @assignment && @assessment && @tutorial

          respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))

        elsif params[:assignment_id] && params[:tutorial_id]
          @assignment = Assignment.find_by(id: params[:assignment_id])
          @tutorial = Tutorial.find_by(id: params[:tutorial_id])
          @assessment = @assignment.assessment
          return if @assignment && @tutorial && @assessment

          respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
        end
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
