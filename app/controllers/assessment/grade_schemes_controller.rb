module Assessment
  class GradeSchemesController < ApplicationController
    before_action :set_assessment
    before_action :set_grade_scheme, only: [:edit, :update, :apply, :destroy]
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    def new
      authorize! :update, @assessment

      existing_scheme  = @assessment.grade_scheme
      existing_config  = existing_scheme&.config || {}
      existing_step    = existing_scheme&.points_step || 1
      @grade_scheme = GradeScheme.new(
        assessment: @assessment,
        kind: :banded,
        config: existing_config,
        points_step: existing_step
      )
      render_dashboard("grades")
    end

    def edit
      authorize! :update, @assessment
      render_dashboard("grades")
    end

    def create
      authorize! :update, @assessment

      @grade_scheme = GradeScheme.new(
        grade_scheme_params.merge(assessment: @assessment, active: true)
      )

      saved = false
      GradeScheme.transaction do
        @assessment.grade_scheme&.update!(active: false)
        saved = @grade_scheme.save
        raise(ActiveRecord::Rollback) unless saved
      end

      if saved
        @grade_scheme = nil
        @assessment.reload
        render_dashboard("grades",
                         notice: I18n.t("assessment.grade_scheme.created"))
      else
        render_dashboard("grades",
                         alert: @grade_scheme.errors.full_messages.join(", "),
                         status: :unprocessable_content)
      end
    end

    def update
      authorize! :update, @assessment

      if @grade_scheme.update(grade_scheme_params)
        @grade_scheme = nil
        render_dashboard("grades",
                         notice: I18n.t("assessment.grade_scheme.updated"))
      else
        render_dashboard("grades",
                         alert: @grade_scheme.errors.full_messages.join(", "),
                         status: :unprocessable_content)
      end
    end

    def apply
      authorize! :update, @assessment

      was_applied = @grade_scheme.applied?
      applier = GradeSchemeApplier.new(@grade_scheme)
      newly_graded = applier.apply!(applied_by: current_user)

      notice = if was_applied
        I18n.t("assessment.grade_scheme.reapplied", count: newly_graded)
      else
        I18n.t("assessment.grade_scheme.applied")
      end

      redirect_to_dashboard(tab: "grades", notice: notice)
    end

    def destroy
      authorize! :update, @assessment

      if @grade_scheme.applied?
        return render_dashboard(
          "grades",
          alert: I18n.t("assessment.grade_scheme.discard_blocked_applied"),
          status: :unprocessable_content
        )
      end

      previous = GradeScheme
                 .where(assessment: @assessment, active: false)
                 .where.not(applied_at: nil)
                 .order(applied_at: :desc)
                 .first

      GradeScheme.transaction do
        @grade_scheme.destroy!
        previous&.update!(active: true)
      end

      @grade_scheme = nil
      render_dashboard("grades",
                       notice: I18n.t("assessment.grade_scheme.discarded"))
    end

    private

      def set_assessment
        @assessment = ::Assessment::Assessment.find_by(id: params[:assessment_id])
        return if @assessment

        redirect_to root_path, alert: I18n.t("assessment.errors.no_assessment")
      end

      def set_grade_scheme
        @grade_scheme = GradeScheme.find_by(
          id: params[:id], assessment: @assessment
        )

        unless @grade_scheme
          return redirect_to_dashboard(
            tab: "grades",
            alert: I18n.t("assessment.grade_scheme.not_found")
          )
        end

        return if @grade_scheme.active?

        redirect_to_dashboard(
          tab: "grades",
          alert: I18n.t("assessment.grade_scheme.not_found")
        )
      end

      def set_locale
        I18n.locale = @assessment&.assessable&.lecture&.locale_with_inheritance ||
                      current_user.locale ||
                      I18n.default_locale
      end

      def grade_scheme_params
        config_json = params.require(:config_json)
        config = begin
          JSON.parse(config_json)
        rescue JSON::ParserError
          raise(ActionController::BadRequest, "Malformed config_json")
        end
        result = { config: config }
        result[:kind] = params[:kind] if params[:kind].present?
        result[:points_step] = params[:points_step].to_f if params[:points_step].present?
        result
      end

      def render_dashboard(tab, notice: nil, alert: nil, status: :ok)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = notice if notice
            flash.now[:alert] = alert if alert

            streams = [
              turbo_stream.update(
                dashboard_container,
                build_dashboard_component(active_tab: tab)
              )
            ]
            streams << stream_flash if flash.present?
            render turbo_stream: streams, status: status
          end
          format.html do
            redirect_to_dashboard(tab: tab, notice: notice, alert: alert)
          end
        end
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

      def build_dashboard_component(active_tab: nil)
        assessable = @assessment.assessable
        AssessmentDashboardComponent.new(
          assessable: assessable,
          assessment: @assessment,
          lecture: assessable.lecture,
          active_tab: active_tab,
          tasks: @assessment.tasks.order(:position),
          grade_scheme: @grade_scheme
        )
      end

      def dashboard_container
        assessable = @assessment.assessable
        assessable.is_a?(Exam) ? "exams_container" : "assessments_container"
      end
  end
end
