module Assessment
  class GradesController < ApplicationController
    include ExamStreams

    before_action :set_resources, only: [:update, :refresh]
    before_action :authorize_assessment!, only: [:update, :refresh]
    before_action :refuse_unless_gradable, only: [:update, :refresh]

    rescue_from ActiveRecord::RecordNotFound do
      respond_with_flash(:alert, I18n.t("assessment.errors.invalid_request_params"))
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_with_flash(:alert, e.record.errors.full_messages.to_sentence)
    end

    rescue_from GradeEntryService::GradeEntryError do |e|
      respond_with_flash(:alert, e.message)
    end

    def authorize_assessment!
      authorize! :enter_grades, @lecture if @lecture.present?
    end

    def update
      grade_info = GradeEntryService.build_grade_info(grade_numeric: params[:grade])
      GradeEntryService.set_grade(@participation, grade_info, current_user, params[:comment])
      @participation.reload
      flash.now[:notice] = t("assessment.grades_updated")
      render turbo_stream: (row_streams + [stream_flash]).compact
    end

    def refresh
      render turbo_stream: row_streams
    end

    private

      def row_streams
        return exam_streams if @assessable.is_a?(Exam)

        row = ParticipationRowComponent.new(assessment: @assessment, grading_scope: @lecture,
                                            participation: @participation, table_option: :grading)
        summary = TalkGradingTableComponent.new(seminar: @lecture).summary
        [turbo_stream.replace("grading-participation-row-#{@participation.id}",
                              html: render_to_string(row)),
         turbo_stream.replace("marking-summary", html: render_to_string(summary))]
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
      # TaskPointsController; a talk is graded for its speakers, an exam for
      # its roster.
      def refuse_unless_gradable
        return respond_with_flash(:alert, t("assessment.errors.no_assessment")) unless @assessment

        case @assessable
        when Talk
          return if @assessable.speakers.exists?(id: @user.id)

          respond_with_flash(:alert, t("assessment.talk_grader.user_not_speaker"))
        when Exam
          return if @assessable.users.exists?(id: @user.id)

          respond_with_flash(:alert, t("assessment.grading_exam.user_not_candidate"))
        else
          respond_with_flash(:alert, t("assessment.errors.not_gradable"))
        end
      end

      def current_ability
        @current_ability ||= AssessmentAbility.new(current_user)
      end
  end
end
