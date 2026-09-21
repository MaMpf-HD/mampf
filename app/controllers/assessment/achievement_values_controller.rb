module Assessment
  # The value a tutor enters for somebody on an achievement, from the row
  # of its table - a group's on the tutor's page, the lecture's in the
  # achievement's dashboard.
  class AchievementValuesController < ApplicationController
    include AchievementStreams

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
      render turbo_stream: [row_stream, summary_stream, delete_button_stream, stream_flash]
    end

    # Somebody else may have entered since the table was drawn; the summary
    # counts them too.
    def refresh
      render turbo_stream: [row_stream, summary_stream]
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

      # A tutor may enter for the group that holds the row - the student's
      # current one while the row is blank - an editor for the lecture. Asked
      # again on the locked row before the write.
      def authorize_entry!(row = @participation)
        authorize!(:enter_points, ParticipationIndex.group_holding(row) || @lecture)
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
        achievement_summary_stream(@achievement, table_scope)
      end

      def delete_button_stream
        achievement_delete_button_stream(@achievement)
      end
  end
end
