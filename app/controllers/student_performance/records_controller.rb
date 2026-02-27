module StudentPerformance
  class RecordsController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
    before_action :set_record, only: :show

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def index
      scope = @lecture.student_performance_records
                      .includes(:user)
                      .order(:computed_at)

      if params[:tutorial_id].present?
        user_ids = TutorialMembership
                   .where(tutorial_id: params[:tutorial_id])
                   .select(:user_id)
        scope = scope.where(user_id: user_ids)
      end

      @pagy, @records = pagy(scope)
    end

    def show
    end

    def recompute
      user_id = params[:user_id].presence

      if user_id
        PerformanceRecordUpdateJob.perform_async(@lecture.id, user_id.to_i)
      else
        PerformanceRecordUpdateJob.perform_async(@lecture.id)
      end

      respond_to do |format|
        format.turbo_stream do
          msg = if user_id
            I18n.t("student_performance.records.recompute.single")
          else
            I18n.t("student_performance.records.recompute.all")
          end
          flash.now[:notice] = msg
          render turbo_stream: stream_flash
        end
        format.html do
          redirect_to lecture_student_performance_records_path(@lecture),
                      notice: I18n.t(
                        "student_performance.records.recompute.all"
                      )
        end
      end
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path,
                    alert: I18n.t("student_performance.errors.no_lecture")
      end

      def set_record
        @record = @lecture.student_performance_records.find_by(id: params[:id])
        return if @record

        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.errors.no_record")
      end

      def authorize_lecture
        authorize!(:edit, @lecture)
      end

      def use_lecture_locale
        locale = @lecture&.locale_with_inheritance || I18n.default_locale
        I18n.locale = locale
      end
  end
end
