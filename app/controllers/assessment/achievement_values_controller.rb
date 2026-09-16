module Assessment
  # The value a tutor enters for somebody on an achievement, from the row
  # of its table - a group's on the tutor's page, the lecture's in the
  # achievement's dashboard.
  class AchievementValuesController < ApplicationController
    before_action :set_resources
    before_action :set_locale
    before_action :authorize_entry!

    rescue_from ActiveRecord::RecordNotFound do
      respond_with_flash(:alert, I18n.t("assessment.errors.invalid_request_params"))
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_with_flash(:alert, e.record.errors.full_messages.to_sentence)
    end

    rescue_from AchievementValueService::InvalidValueError,
                GradeEntryService::GradeEntryError do |e|
      respond_with_flash(:alert, e.message)
    end

    def update
      AchievementValueService.enter(@participation, params[:grade], current_user) do |row|
        authorize_entry!(row)
      end
      @participation.reload
      flash.now[:notice] = t("assessment.achievements.marking.saved")
      render turbo_stream: [row_stream, summary_stream, stream_flash].compact
    end

    def refresh
      render turbo_stream: row_stream
    end

    private

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end

      def set_locale
        I18n.locale = @lecture&.locale_with_inheritance || current_user.locale ||
                      I18n.default_locale
      end

      def set_resources
        @participation = Participation.find(params[:participation_id])
        @assessment = @participation.assessment
        @achievement = @assessment.assessable
        raise(ActiveRecord::RecordNotFound) unless @achievement.is_a?(Achievement)

        @lecture = @achievement.lecture
      end

      # The row belongs to the group that holds it; a tutor may enter for
      # their group, an editor for the lecture. Asked again on the locked
      # row before the write: a blank row follows the student to their new
      # group whenever a table draws.
      def authorize_entry!(row = @participation)
        authorize!(:enter_points, row.tutorial || @lecture)
      end

      # grading_scope_type selects the table to answer into, not the permission
      # scope.
      def table_scope
        (@participation.tutorial if params[:grading_scope_type] == "tutorial") || @lecture
      end

      def row_stream
        row = ParticipationRowComponent.new(participation: @participation, assessment: @assessment,
                                            grading_scope: table_scope, table_option: :achievement)
        turbo_stream.replace("achievement-participation-row-#{@participation.id}",
                             html: render_to_string(row))
      end

      def summary_stream
        summary = AchievementMarkingTableComponent.new(achievement: @achievement,
                                                       grading_scope: table_scope).summary
        turbo_stream.replace("pointing-summary", html: render_to_string(summary))
      end
  end
end
