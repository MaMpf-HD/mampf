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

    def edit
      @rule = StudentPerformance::Rule
              .find_or_initialize_by(lecture: @lecture)
      @achievements = Achievement.where(lecture: @lecture).order(:title)
      @selected_achievement_ids = @rule.rule_achievement_ids_set
    end

    def update
      @source_frame = params[:source_frame].presence
      @rule = StudentPerformance::Rule
              .find_or_initialize_by(lecture: @lecture)

      ActiveRecord::Base.transaction do
        apply_threshold_params
        @rule.active = true
        @rule.save!
        sync_rule_achievements
      end

      target = if @source_frame == "performance-records-frame"
        lecture_student_performance_records_path(@lecture)
      else
        lecture_student_performance_certifications_path(@lecture)
      end

      redirect_to target,
                  notice: I18n.t("student_performance.rules.flash.updated")
    rescue ActiveRecord::RecordInvalid
      @threshold_mode = params.dig(:rule, :threshold_mode)
      @achievements = Achievement.where(lecture: @lecture).order(:title)
      @selected_achievement_ids = Set.new(
        Array(params.dig(:rule, :achievement_ids)).map(&:to_i)
      )
      render :edit, status: :unprocessable_content
    end

    def preview
      @rule = StudentPerformance::Rule
              .where(lecture: @lecture, active: true)
              .includes(rule_achievements: :achievement)
              .first

      unless @rule
        render :preview
        return
      end

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

        { from: current.proposed_status, to: preview.proposed_status }
      end

      @newly_passed = @changes.count { |c| c[:to] == :passed }
      @newly_failed = @changes.count { |c| c[:to] == :failed }
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

      def apply_threshold_params
        mode = params.dig(:rule, :threshold_mode)
        @rule.threshold_mode = mode
        if mode == "percentage"
          @rule.min_percentage = params.dig(:rule, :min_percentage)
          @rule.min_points_absolute = nil
        elsif mode == "absolute"
          @rule.min_points_absolute = params.dig(:rule, :min_points_absolute)
          @rule.min_percentage = nil
        else
          @rule.min_percentage = nil
          @rule.min_points_absolute = nil
        end
      end

      def sync_rule_achievements
        lecture_achievement_ids = Achievement.where(lecture: @lecture)
                                             .pluck(:id).to_set
        wanted_ids = Set.new(
          Array(params.dig(:rule, :achievement_ids))
            .compact_blank.map(&:to_i)
        ) & lecture_achievement_ids
        existing = @rule.rule_achievements.index_by(&:achievement_id)

        (existing.keys.to_set - wanted_ids).each do |removed_id|
          existing[removed_id].destroy!
        end

        position = 1
        wanted_ids.each do |aid|
          if existing[aid]
            existing[aid].update!(position: position)
          else
            @rule.rule_achievements.create!(
              achievement_id: aid, position: position
            )
          end
          position += 1
        end
      end

      def build_preview_rule
        mode = params.dig(:rule, :threshold_mode)
        pct = (params.dig(:rule, :min_percentage).presence&.to_f if mode == "percentage")
        pts = (params.dig(:rule, :min_points_absolute).presence&.to_f if mode == "absolute")

        achievement_ids = Set.new(
          Array(params.dig(:rule, :achievement_ids))
            .compact_blank.map(&:to_i)
        )
        achievements = Achievement.where(
          id: achievement_ids, lecture: @lecture
        )

        PreviewRule.new(
          min_percentage: pct,
          min_points_absolute: pts,
          required_achievements: achievements
        )
      end
  end
end
