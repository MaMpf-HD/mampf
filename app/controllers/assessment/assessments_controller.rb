module Assessment
  class AssessmentsController < BaseController
    before_action :set_lecture, only: [:index]
    before_action :set_assessable, only: [:show]
    before_action :set_assessment, only: [:update]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def index
      authorize! :index, @lecture

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "assessments_container",
            AssessmentsIndexComponent.new(lecture: @lecture)
          )
        end
      end
    end

    def show
      @assessment = @assessable.assessment
      @lecture = @assessable.lecture

      unless @assessment
        redirect_to assessment_assessments_path(lecture_id: @lecture.id),
                    alert: I18n.t("assessment.errors.no_assessment")
        return
      end

      authorize! :show, @assessment

      @tasks = @assessment.tasks.order(:position)
      @participations_count = @assessment.assessment_participations.count

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "assessments_container",
            partial: "assessment/assessments/card_body_show",
            locals: { assessable: @assessable,
                      assessment: @assessment,
                      lecture: @lecture,
                      tasks: @tasks,
                      participations_count: @participations_count,
                      tab: params[:tab] }
          )
        end
      end
    end

    def update
      authorize! :update, @assessment

      if @assessment.update(assessment_params)
        @assessable = @assessment.assessable
        @lecture = @assessable.lecture
        @tasks = @assessment.tasks.order(:position)
        @participations_count = @assessment.assessment_participations.count

        respond_to do |format|
          format.turbo_stream do
            flash.now[:success] = I18n.t("assessment.updated")
            render turbo_stream: [
              turbo_stream.update(
                "assessments_container",
                partial: "assessment/assessments/card_body_show",
                locals: { assessable: @assessable,
                          assessment: @assessment,
                          lecture: @lecture,
                          tasks: @tasks,
                          participations_count: @participations_count,
                          tab: params[:tab] || "settings" }
              ),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            flash.now[:alert] = @assessment.errors.full_messages.join(", ")
            render turbo_stream: stream_flash
          end
        end
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: I18n.t("controllers.no_lecture")
      end

      def set_assessable
        assessable_type = params[:assessable_type]
        assessable_id = params[:assessable_id]

        if assessable_type == "Assignment"
          @assessable = Assignment.find_by(id: assessable_id)
        elsif assessable_type == "Talk"
          @assessable = Talk.find_by(id: assessable_id)
        end

        return if @assessable

        redirect_to root_path, alert: I18n.t("assessment.errors.no_assessable")
      end

      def set_locale
        I18n.locale = @lecture&.locale_with_inheritance ||
                      @assessable&.lecture&.locale_with_inheritance ||
                      @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end

      def set_assessment
        @assessment = Assessment.find_by(id: params[:id])
        return if @assessment

        redirect_to root_path, alert: I18n.t("assessment.errors.no_assessment")
      end

      def assessment_params
        params.require(:assessment_assessment).permit(
          assessable_attributes: [:id, :title, :deadline, :medium_id,
                                  :accepted_file_type, :deletion_date]
        )
      end
  end
end
