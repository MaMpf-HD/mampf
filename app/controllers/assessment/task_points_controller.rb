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
                                                 :refresh_user]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.task_points.invalid_submission_params"))
    end

    rescue_from SubmissionGraderService::SubmissionGraderError,
                PointEntryService::PointEntryError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      authorize! :grade, @tutorial if @tutorial.present?
      authorize! :grade, @lecture if @lecture.present?
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
        SubmissionGraderService.score_multi_teams_by_types!(records, current_user)

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
                                     tutorial: @tutorial,
                                     mode: params[:mode]
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
        render_task_points_update(
          turbo_stream.replace(
            "participation-row-#{@participation.id}",
            html: render_to_string(ParticipationRowComponent.new(
                                     participation: @participation,
                                     assignment: @assignment,
                                     tutorial: @tutorial,
                                     mode: params[:mode]
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

      roster_tutorial = user.tutorial_rosterized(@lecture)
      unless roster_tutorial
        return respond_with_flash(:alert,
                                  t("assessment.task_points.user_not_rostered"))
      end

      authorize! :grade, roster_tutorial
      @tutorial = roster_tutorial
      SubmissionGraderService.init_participation(@assessment, user, @tutorial)
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
                                       tutorial: @tutorial,
                                       mode: params[:mode]
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
                                       participation: @participation,
                                       assignment: @assignment,
                                       tutorial: @tutorial,
                                       mode: params[:mode]
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
              html: render_to_string(TutorialPointingTableComponent.new(
                                       assignment: @assignment,
                                       tutorial: @tutorial,
                                       mode: params[:mode]
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
        elsif params[:assignment_id]
          set_resources_from_assignment
        end
      end

      def set_resources_from_bulk_params
        @tutorial = Tutorial.find_by(id: params["tutorial_id"])
        @assignment = Assignment.find_by(id: params["assignment_id"])

        unless @tutorial
          return respond_with_flash(:alert,
                                    t("assessment.task_points.tutorial_not_found"))
        end

        unless @assignment
          return respond_with_flash(:alert,
                                    t("assessment.task_points.assignment_not_found"))
        end

        @assessment = @assignment.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"))
      end

      def set_resources_from_submission
        @submission = Submission.find_by(id: params[:submission_id])
        unless @submission
          return respond_with_flash(:alert,
                                    t("assessment.task_points.submission_not_found"))
        end

        @assignment = @submission.assignment
        unless @assignment
          return respond_with_flash(:alert,
                                    t("assessment.task_points.submission_missing_assignment"))
        end

        @tutorial = @submission.tutorial
        unless @tutorial
          return respond_with_flash(:alert,
                                    t("assessment.task_points.submission_missing_tutorial"))
        end

        @assessment = @assignment.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.task_points.assignment_missing_assessment"))
      end

      def set_resources_from_participation
        @participation = Participation.find_by(id: params[:participation_id])
        unless @participation
          return respond_with_flash(:alert,
                                    t("assessment.task_points.participation_not_found"))
        end

        @assessment = @participation.assessment
        unless @assessment
          return respond_with_flash(:alert,
                                    t("assessment.task_points.participation_missing_assessment"))
        end

        @tutorial = @participation.tutorial
        unless @tutorial
          return respond_with_flash(:alert,
                                    t("assessment.task_points.participation_missing_tutorial"))
        end

        @assignment = @assessment.assessable
        return if @assignment

        respond_with_flash(:alert, t("assessment.task_points.participation_missing_assignment"))
      end

      def set_resources_from_assignment
        @assignment = Assignment.find_by(id: params[:assignment_id])
        unless @assignment
          return respond_with_flash(:alert,
                                    t("assessment.task_points.assignment_not_found"))
        end

        @tutorial = Tutorial.find_by(id: params[:tutorial_id])
        @lecture = @assignment.lecture
        @assessment = @assignment.assessment
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
