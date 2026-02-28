module StudentPerformance
  # Missing top-level docstring, please formulate one yourself 😁
  class RulesController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def show
      head :ok
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
  end
end
