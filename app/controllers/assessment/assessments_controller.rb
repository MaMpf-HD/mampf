module Assessment
  class AssessmentsController < ApplicationController
    before_action :set_lecture, only: [:index]
    before_action :set_assessable, only: [:show]
    before_action :set_assessment, only: [:update]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def index
      authorize! :index, @lecture

      @active_tab = params[:tab]

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "assessments_container",
            AssessmentsOverviewComponent.new(
              lecture: @lecture, active_tab: @active_tab
            )
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
      @dashboard = build_dashboard_component(active_tab: params[:tab])

      respond_to do |format|
        # The dashboard is a fragment of the lecture's assessment tab, never a
        # page of its own, so anyone arriving directly is sent to that tab —
        # which then loads this very action back into its frame.
        format.html do
          turbo_frame_request? ? render(:show) : redirect_to(dashboard_in_lecture_path)
        end
        format.turbo_stream do
          streams = [turbo_stream.update("assessments_container", @dashboard)]
          streams << stream_flash if flash.present?
          render turbo_stream: streams
        end
      end
    end

    def update
      authorize! :update, @assessment

      @assessable = @assessment.assessable
      @lecture = @assessable.lecture
      @tasks = @assessment.tasks.order(:position)

      if @assessment.update(assessment_params)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:success] = I18n.t("assessment.updated")
            render turbo_stream: [
              turbo_stream.update(
                "assessments_container",
                build_dashboard_component(
                  active_tab: params[:tab] || "settings"
                )
              ),
              stream_flash
            ]
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.update(
              "assessments_container",
              build_dashboard_component(
                active_tab: params[:tab] || "settings"
              )
            ), status: :unprocessable_content
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
        @assessment = ::Assessment::Assessment.find_by(id: params[:id])
        return if @assessment

        redirect_to root_path, alert: I18n.t("assessment.errors.no_assessment")
      end

      def dashboard_in_lecture_path
        edit_lecture_path(@lecture,
                          tab: "assessments",
                          assessment_id: @assessment.id,
                          assessable_type: @assessable.class.name,
                          assessable_id: @assessable.id,
                          assessment_tab: params[:tab])
      end

      def build_dashboard_component(active_tab: nil)
        AssessmentDashboardComponent.new(
          assessable: @assessable,
          assessment: @assessment,
          lecture: @lecture,
          active_tab: active_tab,
          tasks: @tasks
        )
      end

      def assessment_params
        params.expect(
          assessment_assessment: [:requires_submission,
                                  { assessable_attributes: [:id, :title, :deadline, :medium_id,
                                                            :accepted_file_type] }]
        )
      end
  end
end
