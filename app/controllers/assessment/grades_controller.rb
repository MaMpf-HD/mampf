module Assessment
  class GradesController < ApplicationController
    before_action :set_resources, only: [:update, :refresh]
    before_action :set_locale
    before_action :authorize_assessment!, only: [:update, :refresh]
    before_action :refuse_unless_talk_exam, only: [:update, :refresh]

    rescue_from ActiveRecord::RecordNotFound do
      respond_with_flash(:alert, I18n.t("assessment.errors.invalid_request_params"))
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_with_flash(:alert, e.record.errors.full_messages.to_sentence)
    end

    rescue_from TalkGraderService::TalkGraderError,
                ExamGraderService::ExamGraderError,
                GradeEntryService::GradeEntryError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      authorize! :enter_grades, @lecture if @lecture.present?
    end

    def update
      case @assessable
      when Talk
        TalkGraderService.set_grade(@participation, params[:grade], current_user, params[:comment])
      when Exam
        ExamGraderService.set_grade(@participation, params[:grade], current_user, params[:comment])
      end
      @participation.reload
      flash.now[:notice] = t("assessment.grades_updated")
      render turbo_stream: [replace_participation_row, summary_stream, stream_flash].compact
    end

    def refresh
      render turbo_stream: [replace_participation_row, summary_stream]
    end

    private

      def replace_participation_row
        turbo_stream.replace(
          "grading-participation-row-#{@participation.id}",
          html: render_to_string(ParticipationRowComponent.new(
                                   assessment: @assessment,
                                   grading_scope: @lecture,
                                   participation: @participation,
                                   table_option: :grading
                                 ))
        )
      end

      # Saving a grade can change the participation status, so update
      # pointing-summary along with the row.
      def summary_stream
        statuses = TalkGradingTableComponent.new(seminar: @lecture).row_statuses
        summary = PointingSummaryComponent.new(statuses: statuses, hand_ins: false)
        turbo_stream.replace("pointing-summary", html: render_to_string(summary))
      end

      def set_resources
        @participation = Participation.find(params[:participation_id])
        @assessment = @participation.assessment
        @user = @participation.user
        @assessable = @assessment&.assessable
        @lecture = @assessable&.lecture
      end

      # After the authorization, so an outsider learns nothing about the row
      # from the answer. Assignments receive task points through
      # TaskPointsController.
      def refuse_unless_talk_exam
        return respond_with_flash(:alert, t("assessment.errors.no_assessment")) unless @assessment
        unless @assessable.is_a?(Talk) || @assessable.is_a?(Exam)
          return respond_with_flash(:alert, t("assessment.errors.not_gradable"))
        end
        return unless @assessable.is_a?(Talk)
        return if @assessable.speakers.exists?(id: @user.id)

        respond_with_flash(:alert, t("assessment.talk_grader.user_not_speaker"))
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
