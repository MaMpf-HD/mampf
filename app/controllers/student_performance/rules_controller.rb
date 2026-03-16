module StudentPerformance
  # Controller for managing student performance rules, including showing the
  # active rule for a lecture.
  class RulesController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def show
      @rule = StudentPerformance::Rule
              .where(lecture: @lecture, active: true)
              .includes(rule_achievements: :achievement)
              .first
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path,
                    alert: I18n.t("student_performance.errors.no_lecture")
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
