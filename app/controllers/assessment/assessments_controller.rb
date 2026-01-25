module Assessment
  class AssessmentsController < BaseController
    before_action :set_lecture, only: [:index]
    before_action :set_assessable, only: [:show]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def index
      authorize! :index, @lecture

      all_talks = @lecture.talks
                          .includes(:assessment, :speakers, lecture: :term)
                          .order(:position)
      talks_with_speakers = all_talks.select { |talk| talk.speakers.any? }
      @talks_without_speakers = all_talks.reject { |talk| talk.speakers.any? }

      assignments = @lecture.assignments
                            .includes(:assessment, medium: :tags, lecture: :term)
                            .order(created_at: :desc)

      @assessables_by_type = {}
      @lecture.supported_assessable_types.each do |type|
        @assessables_by_type[type] = []
      end
      @assessables_by_type["Talk"] = talks_with_speakers if @assessables_by_type.key?("Talk")
      @assessables_by_type["Assignment"] = assignments if @assessables_by_type.key?("Assignment")

      @assessables_with_assessment = @assessables_by_type.values.flatten
                                                         .select(&:assessment)
      @legacy_assessables = @assessables_by_type.values.flatten
                                                .reject(&:assessment)

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "assessment-assessments-card-body",
            partial: "assessment/assessments/card_body_index",
            locals: { lecture: @lecture,
                      assessables_by_type: @assessables_by_type,
                      assessables_with_assessment: @assessables_with_assessment,
                      legacy_assessables: @legacy_assessables,
                      talks_without_speakers: @talks_without_speakers }
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
          render turbo_stream: turbo_stream.replace(
            "assessment-assessments-card-body",
            partial: "assessment/assessments/card_body_show",
            locals: { assessable: @assessable,
                      assessment: @assessment,
                      lecture: @lecture,
                      tasks: @tasks,
                      participations_count: @participations_count }
          )
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
                      current_user.locale ||
                      I18n.default_locale
      end
  end
end
