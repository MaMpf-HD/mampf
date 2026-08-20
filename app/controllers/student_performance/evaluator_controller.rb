module StudentPerformance
  # Controller for evaluating student performance records based on defined rules.
  class EvaluatorController < ApplicationController
    include StudentPerformance::LectureScoped

    before_action :set_rule

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def single_proposal
      unless @rule
        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.evaluator.no_rule")
        return
      end

      @record = @lecture.student_performance_records
                        .includes(:user)
                        .find_by(id: params[:record_id])

      unless @record
        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.errors.no_record")
        return
      end

      evaluator = StudentPerformance::Evaluator.new(@rule)
      @result = evaluator.evaluate(@record)
    end

    private

      def set_rule
        @rule = StudentPerformance::Rule
                .where(lecture: @lecture, active: true)
                .includes(rule_achievements: :achievement)
                .first
      end
  end
end
