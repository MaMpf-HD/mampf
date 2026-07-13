module Assessment
  class GradesController < ApplicationController
    before_action :set_talk_resource,
                  only: [:update, :mark_absent, :mark_exempt, :refresh]
    before_action :set_locale
    before_action :authorize_assessment!,
                  only: [:update, :mark_absent, :mark_exempt]

    rescue_from ActiveRecord::RecordNotFound,
                ActiveRecord::RecordInvalid do |_e|
      respond_with_flash(:alert, I18n.t("assessment.grades.invalid_params"))
    end

    rescue_from Assessment::GradeEntryService::GradeEntryError,
                Assessment::AbsenceHandling::AbsenceHandlingError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      authorize! :grade, @lecture if @lecture.present?
    end

    def update
      Assessment::GradeEntryService.set_grade(
        @participation, params[:grade], current_user, params[:comment]
      )
      @participation = @participation.reload
      render_grade_update(replace_participation_row)
    end

    def mark_absent
      # Assessment::AbsenceHandling.mark_absent(@participation, current_user)
      @participation = @participation.reload
      render_grade_update(replace_participation_row)
    end

    def mark_exempt
      # Assessment::AbsenceHandling.mark_exempt(@participation, current_user)
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
          html: render_to_string(GradeTalkRowComponent.new(
                                   participation: @participation,
                                   talk: @talk
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
        flash.now[:notice] = t("assessment.grades.update")
        render turbo_stream: streams.flatten.compact + [stream_flash].compact
      end

      def set_talk_resource
        if params[:participation_id]
          set_resources_from_participation
        elsif params[:talk_id]
          set_resources_from_talk
        end
      end

      def set_resources_from_participation
        @participation = Assessment::Participation.find_by(id: params[:participation_id])
        unless @participation
          return respond_with_flash(:alert,
                                    t("assessment.grades.participation_not_found"))
        end

        @assessment = @participation.assessment
        unless @assessment
          return respond_with_flash(:alert,
                                    t("assessment.grades.participation_missing_assessment"))
        end

        @talk = @assessment.assessable
        unless @talk
          return respond_with_flash(:alert,
                                    t("assessment.grades.participation_missing_talk"))
        end

        @lecture = @talk.lecture
      end

      def set_resources_from_talk
        @talk = Talk.find_by(id: params[:talk_id])
        return respond_with_flash(:alert, t("assessment.grades.talk_not_found")) unless @talk

        @lecture = @talk.lecture
        @assessment = @talk.assessment
        return if @assessment

        respond_with_flash(:alert, t("assessment.grades.talk_missing_assessment"))
      end

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_locale
        I18n.locale = @lecture&.locale_with_inheritance ||
                      @talk&.lecture&.locale_with_inheritance ||
                      @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
