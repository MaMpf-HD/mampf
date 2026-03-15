module StudentPerformance
  # Controller for evaluating student performance records based on defined rules.
  class EvaluatorController < ApplicationController
    before_action :set_lecture
    before_action :authorize_lecture
    before_action :use_lecture_locale
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

      preview_rule = build_preview_rule

      records = @lecture.student_performance_records
                        .includes(:user)
                        .order(:created_at)

      current_eval = StudentPerformance::Evaluator.new(@rule)
      preview_eval = StudentPerformance::Evaluator.new(preview_rule)

      @changes = records.filter_map do |record|
        current = current_eval.evaluate(record)
        preview = preview_eval.evaluate(record)
        next if current.proposed_status == preview.proposed_status

        {
          record: record,
          from: current.proposed_status,
          to: preview.proposed_status
        }
      end

      @newly_passed = @changes.count { |c| c[:to] == :passed }
      @newly_failed = @changes.count { |c| c[:to] == :failed }
      @newly_inconclusive = @changes.count { |c| c[:to] == :inconclusive }
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

    PreviewRule = Struct.new(
      :min_percentage,
      :min_points_absolute,
      :required_achievements,
      keyword_init: true
    )

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

      def set_rule
        @rule = StudentPerformance::Rule
                .where(lecture: @lecture, active: true)
                .includes(rule_achievements: :achievement)
                .first
      end

      def build_preview_rule
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
