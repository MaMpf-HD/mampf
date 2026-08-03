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

    def bulk_proposals
      unless @rule
        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.evaluator.no_rule")
        return
      end

      records = @lecture.student_performance_records
                        .includes(:user)
                        .order(:created_at)

      evaluator = StudentPerformance::Evaluator.new(@rule)
      @proposals = evaluator.bulk_evaluate(records)
      @passed_count = @proposals.count { |_, r| r.proposed_status == :passed }
      @failed_count = @proposals.count { |_, r| r.proposed_status == :failed }
      @inconclusive_count = @proposals.count { |_, r| r.proposed_status == :inconclusive }
    end

    def preview_rule_change
      unless @rule
        redirect_to lecture_student_performance_records_path(@lecture),
                    alert: I18n.t("student_performance.evaluator.no_rule")
        return
      end

      @preview_percentage = params.dig(:preview, :min_percentage)
      @preview_points = params.dig(:preview, :min_points_absolute)

      preview = StudentPerformance::RuleChangePreview.new(
        current_rule: @rule,
        preview_rule: rule_with_preview_thresholds,
        records: @lecture.student_performance_records.includes(:user).order(:created_at)
      )

      @changes = preview.changes
      @newly_passed = preview.newly(:passed)
      @newly_failed = preview.newly(:failed)
      @newly_inconclusive = preview.newly(:inconclusive)
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

      # The saved rule with the what-if thresholds swapped in; its achievements
      # stay as they are, because this screen does not offer to change them.
      def rule_with_preview_thresholds
        pct = @preview_percentage.presence&.to_f
        pts = @preview_points.presence&.to_f

        if pct.nil? && pts.nil?
          pct = @rule.min_percentage if @rule.min_percentage.present?
          pts = @rule.min_points_absolute if @rule.min_points_absolute.present?
        end

        PreviewRule.new(
          min_percentage: pct,
          min_points_absolute: pts,
          required_achievements: @rule.required_achievements
        )
      end
  end
end
