module Assessment
  class TasksController < ApplicationController
    before_action :set_assessment
    before_action :set_task, only: [:edit, :update, :destroy, :cancel]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def edit
      authorize! :update, @assessment

      index = @assessment.tasks.order(:position).pluck(:id).index(@task.id)
      index = index ? index + 1 : @task.position

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
      authorize! :update, @assessment

      index = @assessment.tasks.order(:position).pluck(:id).index(@task.id)
      index = index ? index + 1 : @task.position

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
      authorize! :update, @assessment

      @task = @assessment.tasks.build(task_params)

      if @task.save
        redirect_to_dashboard(tab: "tasks", notice: I18n.t("assessment.task.created"))
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
      authorize! :update, @assessment

      task = @assessment.tasks.find(params[:task_id])
      task.insert_at(params[:position].to_i)

      head :ok
    rescue ActiveRecord::RecordNotFound
      head :bad_request
    end

    def update
      authorize! :update, @assessment

      if @task.update(task_params)
        redirect_to_dashboard(tab: "tasks", notice: I18n.t("assessment.task.updated"))
      else
        index = @assessment.tasks.order(:position).pluck(:id).index(@task.id)
        index = index ? index + 1 : @task.position

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
        params.expect(assessment_task: [:max_points, :description])
      end

      def redirect_to_dashboard(tab:, notice: nil, alert: nil)
        assessable = @assessment.assessable
        flash[:notice] = notice if notice
        flash[:alert] = alert if alert

        if assessable.is_a?(Exam)
          redirect_to exam_path(assessable, tab: tab)
        else
          redirect_to assessment_assessment_path(
            @assessment,
            assessable_type: assessable.class.name,
            assessable_id: assessable.id,
            tab: tab
          )
        end
      end

      def dashboard_turbo_args(tab:, task: nil)
        assessable = @assessment.assessable
        tasks = @assessment.tasks.order(:position)
        container = assessable.is_a?(Exam) ? "exams_container" : "assessments_container"
        component = AssessmentDashboardComponent.new(
          assessable: assessable,
          assessment: @assessment,
          lecture: assessable.lecture,
          active_tab: tab,
          tasks: tasks,
          task: task
        )
        [container, component]
      end
  end
end
