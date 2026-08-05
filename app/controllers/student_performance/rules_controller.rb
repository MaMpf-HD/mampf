module StudentPerformance
  # Controller for managing student performance rules, including showing the
  # active rule for a lecture.
  class RulesController < ApplicationController
    include StudentPerformance::LectureScoped

    rescue_from CanCan::AccessDenied do |exception|
      redirect_to main_app.root_url, alert: exception.message
    end

    def current_ability
      @current_ability ||= LectureAbility.new(current_user)
    end

    def edit
      @source_frame = params[:source_frame]
      @rule = StudentPerformance::Rule
              .find_or_initialize_by(lecture: @lecture)
      @achievements = Achievement.where(lecture: @lecture).order(:title)
      @selected_achievement_ids = @rule.rule_achievement_ids_set
    end

    def update
      @source_frame = params[:source_frame].presence
      @rule = StudentPerformance::Rule
              .find_or_initialize_by(lecture: @lecture)

      apply_threshold_params
      @rule.active = true
      build_rule_achievements
      @rule.save!

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

      preview = StudentPerformance::RuleChangePreview.new(
        current_rule: @rule,
        preview_rule: rule_from_form_params,
        records: @lecture.student_performance_records.includes(:user).order(:created_at)
      )

      @changes = preview.changes
      @newly_passed = preview.newly(:passed)
      @newly_failed = preview.newly(:failed)
      @newly_inconclusive = preview.newly(:inconclusive)
    end

    private

      def apply_threshold_params
        mode = params.dig(:rule, :threshold_mode)
        # Guard the enum assignment: an unknown value would otherwise raise.
        mode = "none" unless StudentPerformance::Rule.threshold_modes.key?(mode)
        @rule.threshold_mode = mode

        case mode
        when "percentage"
          @rule.min_percentage = params.dig(:rule, :min_percentage)
          @rule.min_points_absolute = nil
        when "absolute"
          @rule.min_points_absolute = params.dig(:rule, :min_points_absolute)
          @rule.min_percentage = nil
        else
          @rule.min_percentage = nil
          @rule.min_points_absolute = nil
        end
      end

      # Builds the criteria in memory so that they are present when the rule is
      # validated; the association is autosaved together with the rule.
      def build_rule_achievements
        lecture_achievement_ids = Achievement.where(lecture: @lecture)
                                             .pluck(:id).to_set
        wanted_ids = Set.new(
          Array(params.dig(:rule, :achievement_ids))
            .compact_blank.map(&:to_i)
        ) & lecture_achievement_ids
        existing = @rule.rule_achievements.index_by(&:achievement_id)

        (existing.keys.to_set - wanted_ids).each do |removed_id|
          existing[removed_id].mark_for_destruction
        end

        wanted_ids.each_with_index do |aid, index|
          record = existing[aid] || @rule.rule_achievements.build(achievement_id: aid)
          record.position = index + 1
        end
      end

      # The thresholds the teacher has typed into the rule form, not the ones on
      # record — this is the preview of an unsaved edit.
      def rule_from_form_params
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
