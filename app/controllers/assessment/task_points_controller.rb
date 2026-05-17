module Assessment
  class TaskPointsController < ApplicationController
    before_action :set_assessment
    before_action :set_locale

    def update_team_multi
      scorer = current_user

      case params[:type]
      when "Tutorial"
        submissions = JSON.parse(params[:submissions])

        submissions.each do |entry|
          submission = Submission.find(entry["id"])
          SubmissionGraderService.score_tasks!(
            submission,
            entry["task_points"],
            scorer
          )
        end
        sample_submission = Submission.find_by(id: submissions.first["id"])
        @tutorial = sample_submission.tutorial
        @assignment = sample_submission.assignment
        @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                            &.order(:last_modification_by_users_at)
        @non_submitters = @assignment.non_submitters(@tutorial)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "grading-table",
              partial: "assessment/assessments/components/tutorial_grading_content",
              locals: { assignment: @assignment, tutorial: @tutorial,
                        stack: @stack, non_submitters: @non_submitters }
            )
          end
        end
      end
    end

    def update_team
      scorer = current_user
      task_points = JSON.parse(params[:task_points] || "{}")
      t = params[:type]

      case params[:type]
      when "Tutorial"
        submission = Submission.find_by(id: params[:id])
        SubmissionGraderService.score_tasks!(
          submission,
          task_points,
          scorer
        )
        @submission = submission.reload
        @assignment = @submission.assignment
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "submission-row-#{@submission.id}",
              partial: "tutorials/rows_single",
              locals: { submission: @submission, assignment: @assignment }
            )
          end
        end
      end
    end

    def refresh
      @submission = Submission.find_by(id: params[:id])
      @assignment = @submission.assignment
      rerender_submission_row
    end

    private

      def rerender_submission_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "submission-row-#{@submission.id}",
              partial: "tutorials/rows_single",
              locals: { submission: @submission, assignment: @assignment }
            )
          end
        end
      end

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_assessment
        is_multi_update = params[:id].nil? && params[:submissions].present?
        submission = if is_multi_update
          Submission.find_by(id: JSON.parse(params[:submissions]).first["id"])
        else
          Submission.find_by(id: params[:id])
        end
        @assessment = submission&.assessment
        return if @assessment

        render json: { error: "Assessment not found" }, status: :not_found
        nil
      end

      def set_locale
        I18n.locale = @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
