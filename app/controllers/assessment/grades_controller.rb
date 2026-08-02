module Assessment
  class GradesController < ApplicationController
    before_action :set_talk_and_user_resource,
                  only: [:update, :mark_absent, :mark_exempt, :refresh]
    before_action :set_locale
    before_action :authorize_assessment!,
                  only: [:update, :mark_absent, :mark_exempt]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.grades.invalid_params"))
    end

    # rescue_from Assessment::GradeEntryService::GradeEntryError,
    #             Assessment::AbsenceHandling::AbsenceHandlingError do |e|
    #   respond_with_flash(:alert, e.message)
    # end

    def authorize_assessment!
      authorize! :grade, @lecture if @lecture.present?
    end

    def update
      participation = find_or_create_participation
      TalkGraderService.set_grade(
        participation, params[:grade], current_user, params[:comment]
      )
      @participation = participation.reload
      render_grade_update(replace_participation_row)
    end

    def mark_absent
      participation = find_or_create_participation
      # AbsenceHandling.mark_absent(participation, current_user)
      @participation = participation.reload
      render_grade_update(replace_participation_row)
    end

    def mark_exempt
      participation = find_or_create_participation
      # AbsenceHandling.mark_exempt(participation, current_user)
      @participation = participation.reload
      render_grade_update(replace_participation_row)
    end

    def refresh
      # Participation may not exist yet — that's fine, row just re-renders as "pending"
      @participation = @talk.participations.find_by(user_id: @user.id)
      rerender_participation_row
    end

    private

      def find_or_create_participation
        TalkGraderService.init_participation(@assessment, @user, @talk)
      end

      def replace_participation_row
        turbo_stream.replace(
          "user-row-#{@user.id}",
          html: render_to_string(GradeTalkRowComponent.new(
                                   user: @user,
                                   talk: @talk,
                                   participation: @participation
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
        flash.now[:notice] = t("assessment.talk_grader.grades_updated")
        render turbo_stream: streams.flatten.compact + [stream_flash].compact
      end

      def set_talk_and_user_resource
        @talk = Talk.find_by(id: params[:talk_id])
        return respond_with_flash(:alert, t("assessment.grades.talk_not_found")) unless @talk

        @lecture = @talk.lecture
        @assessment = @talk.assessment
        unless @assessment
          return respond_with_flash(:alert, t("assessment.grades.talk_missing_assessment"))
        end

        @user = User.find_by(id: params[:user_id])
        return respond_with_flash(:alert, t("assessment.grades.user_not_found")) unless @user

        return if @talk.speakers.exists?(id: @user.id)

        respond_with_flash(:alert, t("assessment.grades.user_not_speaker"))
      end

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_locale
        I18n.locale = @lecture&.locale_with_inheritance ||
                      @talk&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
