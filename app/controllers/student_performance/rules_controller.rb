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
        if mode == "percentage"
          value = params.dig(:rule, :min_percentage)
          if value.blank?
            @rule.errors.add(
              :min_percentage,
              I18n.t("student_performance.rules.errors.threshold_blank")
            )
            raise(ActiveRecord::RecordInvalid, @rule)
          end
          @rule.min_percentage = value
          @rule.min_points_absolute = nil
        elsif mode == "absolute"
          value = params.dig(:rule, :min_points_absolute)
          if value.blank?
            @rule.errors.add(
              :min_points_absolute,
              I18n.t("student_performance.rules.errors.threshold_blank")
            )
            raise(ActiveRecord::RecordInvalid, @rule)
          end
          @rule.min_points_absolute = value
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
  end
end
