module Assessment
  class TasksController < ApplicationController
    before_action :set_assessment
    # Structural rather than per action: a forgotten `authorize!` leaves an
    # endpoint open, and nothing fails to remind you.
    before_action :authorize_assessment_update!
    before_action :set_task, only: [:edit, :update, :destroy, :cancel]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def edit
      index = task_display_index(@task)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@task),
            partial: "assessment/tasks/form",
            locals: { task: @task, assessment: @assessment, index: index }
          )
        end
        format.html do
          render partial: "assessment/tasks/form",
                 locals: { task: @task, assessment: @assessment, index: index }
        end
      end
    end

    def cancel
      index = task_display_index(@task)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@task),
            partial: "assessment/tasks/task_card",
            locals: { task: @task, assessment: @assessment, index: index }
          )
        end
      end
    end

    def create
      @task = @assessment.tasks.build(task_params)

      if @task.save
        redirect_to_dashboard(tab: "tasks")
      else
        respond_to do |format|
          format.html do
            redirect_to_dashboard(tab: "tasks", alert: @task.errors.full_messages.join(", "))
          end
          format.turbo_stream do
            target, component = dashboard_turbo_args(tab: "tasks", task: @task)
            render turbo_stream: turbo_stream.update(target, component),
                   status: :unprocessable_content
          end
        end
      end
    end

    def reorder
      task = @assessment.tasks.find(params[:task_id])
      task.insert_at(params[:position].to_i.clamp(1, @assessment.tasks.count))

      head :ok
    rescue ActiveRecord::RecordNotFound
      head :bad_request
    end

    def update
      if @task.update(task_params)
        redirect_to_dashboard(tab: "tasks")
      else
        index = task_display_index(@task)

        respond_to do |format|
          format.html do
            redirect_to_dashboard(tab: "tasks", alert: @task.errors.full_messages.join(", "))
          end
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              ActionView::RecordIdentifier.dom_id(@task),
              partial: "assessment/tasks/form",
              locals: { task: @task, assessment: @assessment, index: index }
            ), status: :unprocessable_content
          end
        end
      end
    end

    def destroy
      if @task.destroy
        redirect_to_dashboard(tab: "tasks")
      else
        redirect_to_dashboard(tab: "tasks", alert: I18n.t("assessment.task.delete_failed"))
      end
    end

    private

      def authorize_assessment_update!
        authorize! :update, @assessment
      end

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
        params.expect(assessment_task: [:max_points, :description])
      end

      def task_display_index(task)
        return task.position unless task.position

        @assessment.tasks.where(position: ...task.position).count + 1
      end

      def redirect_to_dashboard(tab:, alert: nil)
        assessable = @assessment.assessable
        flash[:alert] = alert if alert

        redirect_to assessment_assessment_path(
          @assessment,
          assessable_type: assessable.class.name,
          assessable_id: assessable.id,
          tab: tab
        )
      end

      def dashboard_turbo_args(tab:, task: nil)
        assessable = @assessment.assessable
        tasks = @assessment.tasks.order(:position)
        component = AssessmentDashboardComponent.new(
          assessable: assessable,
          assessment: @assessment,
          lecture: assessable.lecture,
          active_tab: tab,
          tasks: tasks,
          task: task
        )
        ["assessments_container", component]
      end
  end
end
