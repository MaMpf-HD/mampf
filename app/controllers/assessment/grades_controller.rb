module Assessment
  class GradesController < ApplicationController
    before_action :set_assessable_resource,
                  only: [:update, :refresh]
    before_action :set_locale
    before_action :authorize_assessment!,
                  only: [:update, :refresh]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.errors.invalid_request_params"))
    end

    rescue_from TalkGraderService::TalkGraderError,
                GradeEntryService::GradeEntryError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      authorize! :grade, @lecture if @lecture.present?
    end

    def update
      case @assessable
      when Talk
        TalkGraderService.set_grade(
          @participation, params[:grade], current_user, params[:comment]
        )
      end
      @participation = @participation.reload
      render_grade_update(replace_participation_row)
    end

    def refresh
      rerender_participation_row
    end

    private

      def replace_participation_row
        turbo_stream.replace(
          "participation-row-#{@participation.id}",
          html: render_to_string(ParticipationRowComponent.new(
                                   assessment: @assessment,
                                   grading_scope: @lecture,
                                   participation: @participation,
                                   save_url: grade_participation_path(@participation),
                                   refresh_url: refresh_grade_participation_path(@participation),
                                   group_id: @assessable.id
                                 ))
        )
      end

      def rerender_participation_row
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: replace_participation_row
          end
        end
      end

      def render_grade_update(*streams)
        flash.now[:notice] = t("assessment.grades_updated")
        render turbo_stream: streams.flatten.compact + [stream_flash].compact
      end

      def set_assessable_resource
        if params[:talk_id]
          set_resources_from_talk
        elsif params[:participation_id]
          set_resources_from_participation
        end
      end

      def set_resources_from_talk
        @assessable = Talk.find(params[:talk_id])
        @lecture = @assessable.lecture
        @assessment = @assessable.assessment
        @user = User.find(params[:user_id])
        @participation = Participation.find_by(
          assessment_id: @assessment&.id,
          user_id: @user.id
        )
        empty_resource_check
        return if performed?

        return if @assessable.speakers.exists?(id: @user.id)

        respond_with_flash(:alert, t("assessment.talk_grader.user_not_speaker"))
      end

      def set_resources_from_participation
        @participation = Participation.find(params[:participation_id])

        @assessment = @participation.assessment
        @user = @participation.user
        @assessable = @assessment&.assessable
        @lecture = @assessable&.lecture
        empty_resource_check
        return if performed?

        return if @assessable&.speakers&.exists?(id: @user.id)

        respond_with_flash(:alert, t("assessment.talk_grader.user_not_speaker"))
      end

      def empty_resource_check
        return respond_with_flash(:alert, t("assessment.errors.no_assessment")) unless @assessment
        return respond_with_flash(:alert, t("assessment.errors.not_gradable")) unless @assessable
        return respond_with_flash(:alert, t("assessment.errors.user_not_found")) unless @user

        return if @participation

        respond_with_flash(:alert, t("assessment.errors.no_participation"))
      end

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_locale
        I18n.locale = @lecture&.locale_with_inheritance ||
                      @assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
