module Assessment
  class TaskPointsController < ApplicationController
    before_action :set_assignment_resource,
                  only: [:update_team_multi, :update_team,
                         :update_user, :refresh_submission,
                         :refresh_user, :mark_as_participated]
    before_action :set_locale
    before_action :authorize_assessment!, only: [:update_team_multi,
                                                 :update_team,
                                                 :update_user,
                                                 :refresh_submission,
                                                 :refresh_user,
                                                 :mark_as_participated]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.task_points.invalid_submission_params"))
    end

    rescue_from SubmissionGraderService::SubmissionGraderError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      authorize! :grade, @tutorial if @tutorial.present?
    end

    def update_team_multi
      case params[:type]
      when "Tutorial"
        begin
          records = JSON.parse(params[:submissions] || "[]")
        rescue JSON::ParserError
          respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
          return
        end
        ActiveRecord::Base.transaction do
          records.each do |entry|
            SubmissionGraderService.score_tasks_by_types!(entry, current_user,
                                                          tutorial: @tutorial,
                                                          assignment: @assignment)
          end
        end

        @stack = @assignment&.submissions&.where(tutorial: @tutorial)&.proper
                            &.order(:last_modification_by_users_at)
        @non_submitters = @assignment.non_submitters(@tutorial)
        rerender_submission_table
      end
    end

    def update_team
      begin
        task_points = JSON.parse(params[:task_points] || "{}")
      rescue JSON::ParserError
        respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
        return
      end
      case params[:type]
      when "Tutorial"
        ActiveRecord::Base.transaction do
          SubmissionGraderService.score_tasks_by_submission!(
            @submission, task_points, current_user
          )
        end
        @submission = @submission.reload
        @assignment = @submission.assignment
        @tutorial = @submission.tutorial
        render_task_points_update(
          turbo_stream.replace(
            "submission-row-#{@submission.id}",
            html: render_to_string(SubmissionRowComponent.new(
                                     submission: @submission,
                                     assignment: @assignment,
                                     tutorial: @tutorial
                                   ))
          )
        )
      end
    end

    def update_user
      begin
        task_points = JSON.parse(params[:task_points] || "{}")
      rescue JSON::ParserError
        respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
        return
      end
      case params[:type]
      when "Tutorial"
        ActiveRecord::Base.transaction do
          SubmissionGraderService.score_tasks_by_participation!(
            @participation, task_points, current_user
          )
        end
        @user = @participation.user
        render_task_points_update(
          turbo_stream.replace(
            "participation-row-#{@participation.id}",
            html: render_to_string(ParticipationRowComponent.new(
                                     user: @user,
                                     assignment: @assignment,
                                     tutorial: @tutorial
                                   ))
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
      return respond_with_flash(:alert, t("assessment.task_points.user_not_found")) unless user

      SubmissionGraderService.init_participation(@assessment, user, @tutorial)
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
              html: render_to_string(SubmissionRowComponent.new(
                                       submission: @submission,
                                       assignment: @assignment,
                                       tutorial: @tutorial
                                     ))
            )
          end
        end
      end

      def rerender_user_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "participation-row-#{@participation.id}",
              html: render_to_string(ParticipationRowComponent.new(
                                       user: @user,
                                       assignment: @assignment,
                                       tutorial: @tutorial
                                     ))
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
              html: render_to_string(TutorialGradingTableComponent.new(
                                       assignment: @assignment,
                                       tutorial: @tutorial,
                                       stack: @stack,
                                       non_submitters: @non_submitters
                                     ))
            )
          end
        end
      end

      def set_assignment_resource
        if params[:submissions]
          set_resources_from_bulk_params
        elsif params[:submission_id]
          set_resources_from_submission
        elsif params[:participation_id]
          set_resources_from_participation
        elsif params[:assignment_id] && params[:tutorial_id]
          set_resources_from_assignment_and_tutorial
        end
      end

      def set_resources_from_bulk_params
        @tutorial = Tutorial.find_by(id: params["tutorial_id"])
        @assignment = Assignment.find_by(id: params["assignment_id"])
        @assessment = @assignment.assessment if @tutorial && @assignment
        return if @assessment && @tutorial && @assignment

        respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
      end

      def set_resources_from_submission
        @submission = Submission.find_by(id: params[:submission_id])
        if @submission
          @assignment = @submission.assignment
          @tutorial = @submission.tutorial
          @assessment = @assignment.assessment if @assignment
        end
        return if @assessment && @tutorial && @assignment

        respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
      end

      def set_resources_from_participation
        @participation = Participation.find_by(id: params[:participation_id])
        if @participation
          @assessment = @participation.assessment
          @tutorial = @participation.tutorial
          @assignment = @assessment.assessable if @assessment
        end
        return if @tutorial && @assessment && @assignment

        respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
      end

      def set_resources_from_assignment_and_tutorial
        @assignment = Assignment.find_by(id: params[:assignment_id])
        @tutorial = Tutorial.find_by(id: params[:tutorial_id])
        @assessment = @assignment.assessment if @assignment && @tutorial
        return if @assessment && @tutorial && @assignment

        respond_with_flash(:alert, t("assessment.task_points.invalid_submission_params"))
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
