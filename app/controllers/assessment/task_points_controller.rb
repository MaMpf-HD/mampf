module Assessment
  class TaskPointsController < ApplicationController
    before_action :set_assessment, except: [:mark_as_participated, :update_user]
    before_action :set_locale
    # before_action :authorize_assessment_access!

    

    def update_team_multi
      scorer = current_user

      case params[:type]
      when "Tutorial"
        records = JSON.parse(params[:submissions])
        @tutorial = Tutorial.find_by(id: params["tutorial_id"])
        @assignment = Assignment.find_by(id: params["assignment_id"])

        records.each do |entry|
          if entry["target"] == "submission"
            submission = Submission.find(entry["id"])
            SubmissionGraderService.score_tasks_by_submission!(
              submission,
              entry["task_points"],
              scorer
            )
          end

          next unless entry["target"] == "user"

          user = User.find(entry["id"])
          SubmissionGraderService.score_tasks_by_user!(
            user,
            @assignment,
            entry["task_points"],
            scorer
          )
        end

        @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                            &.order(:last_modification_by_users_at)
        @non_submitters = @assignment.non_submitters(@tutorial)
        rerender_submission_table
      end
    end

    def update_team
      scorer = current_user
      task_points = JSON.parse(params[:task_points] || "{}")

      case params[:type]
      when "Tutorial"
        submission = Submission.find_by(id: params[:id])
        SubmissionGraderService.score_tasks_by_submission!(
          submission,
          task_points,
          scorer
        )
        @submission = submission.reload
        @assignment = @submission.assignment
        @tutorial = @submission.tutorial
        rerender_submission_row
      end
    end

    def update_user
      scorer = current_user
      task_points = JSON.parse(params[:task_points] || "{}")
      @assignment = Assignment.find_by(id: params[:assignment_id])
      @tutorial = Tutorial.find_by(id: params[:tutorial_id])

      case params[:type]
      when "Tutorial"
        @participation = Participation.find_by(id: params[:id])
        SubmissionGraderService.score_tasks_by_participation!(
          @participation,
          task_points,
          scorer
        )
        @user = @participation.user
        rerender_user_row
      end
    end

    def refresh_submission
      @submission = Submission.find_by(id: params[:submission_id])
      @assignment = @submission.assignment
      rerender_submission_row
    end

    def refresh_user
      @participation = Participation.find_by(id: params[:id])
      @user = @participation.user
      @assignment = @participation.assignment
      @tutorial = @participation.tutorial
      rerender_user_row
    end

    def mark_as_participated
      user = User.find_by(id: params[:user_id])
      @tutorial = Tutorial.find_by(id: params[:tutorial_id])
      @assignment = Assignment.find_by(id: params[:assignment_id])
      @assessment = @assignment.assessment
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

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_assessment
        @assessment = find_assessment
        return if @assessment

        render json: { error: "Assessment not found" }, status: :not_found
      end

      def find_assessment
        if params[:submissions].present? && params[:id].nil?
          submission = Submission.find_by(id: JSON.parse(params[:submissions]).first["id"])
          submission&.assessment
        elsif params[:id].present?
          submission = Submission.find_by(id: params[:id])
          submission&.assessment ||
            Participation.find_by(id: params[:id])&.assessment
        elsif params[:assignment_id].present?
          Assignment.find_by(id: params[:assignment_id])&.assessment
        end
      end

      def set_locale
        I18n.locale = @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
