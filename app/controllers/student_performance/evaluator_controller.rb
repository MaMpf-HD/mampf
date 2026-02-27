module StudentPerformance
  class EvaluatorController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def bulk_proposals
      head :ok
    end

    def preview_rule_change
      head :ok
    end

    def single_proposal
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
