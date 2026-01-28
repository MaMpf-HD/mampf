module Assessment
  class TasksController < BaseController
    before_action :set_assessment
    before_action :set_task, only: [:edit, :update, :destroy]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def edit
      authorize! :update, @assessment

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@task),
            partial: "assessment/tasks/form",
            locals: { task: @task, assessment: @assessment }
          )
        end
        format.html do
          render partial: "assessment/tasks/form",
                 locals: { task: @task, assessment: @assessment }
        end
      end
    end

    def create
      authorize! :update, @assessment

      @task = @assessment.tasks.build(
        title: "",
        max_points: params[:max_points]
      )

      if @task.save
        redirect_to_dashboard(tab: "tasks", notice: I18n.t("assessment.task.created"))
      else
        redirect_to_dashboard(tab: "tasks", alert: @task.errors.full_messages.join(", "))
      end
    end

    def reorder
      authorize! :update, @assessment

      params[:order].each_with_index do |id, index|
        @assessment.tasks.find(id).update(position: index + 1)
      end

      head :ok
    end

    def update
      authorize! :update, @assessment

      if @task.update(task_params)
        redirect_to_dashboard(tab: "tasks", notice: I18n.t("assessment.task.updated"))
      else
        redirect_to_dashboard(tab: "tasks", alert: @task.errors.full_messages.join(", "))
      end
    end

    def destroy
      authorize! :update, @assessment

      if @task.destroy
        redirect_to_dashboard(tab: "tasks", notice: I18n.t("assessment.task.deleted"))
      else
        redirect_to_dashboard(tab: "tasks", alert: I18n.t("assessment.task.delete_failed"))
      end
    end

    private

      def set_assessment
        @assessment = ::Assessment::Assessment.find_by(id: params[:assessment_id])
        return if @assessment

        redirect_to root_path, alert: I18n.t("assessment.errors.no_assessment")
      end

      def set_task
        @task = @assessment.tasks.find_by(id: params[:id])
        return if @task

        redirect_to_dashboard(tab: "tasks", alert: I18n.t("assessment.errors.no_task"))
      end

      def set_locale
        I18n.locale = @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end

      def task_params
        params.require(:assessment_task).permit(:max_points, :description)
      end

      def redirect_to_dashboard(tab:, notice: nil, alert: nil)
        assessable = @assessment.assessable
        flash[:notice] = notice if notice
        flash[:alert] = alert if alert

        redirect_to assessment_assessment_path(
          @assessment,
          assessable_type: assessable.class.name,
          assessable_id: assessable.id,
          tab: tab
        )
      end
  end
end
