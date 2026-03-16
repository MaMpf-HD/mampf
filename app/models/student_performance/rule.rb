module StudentPerformance
  class Rule < ApplicationRecord
    belongs_to :lecture

    has_many :rule_achievements,
             class_name: "StudentPerformance::RuleAchievement",
             dependent: :destroy
    has_many :required_achievements,
             through: :rule_achievements,
             source: :achievement

    attr_accessor :threshold_mode

    validates :min_percentage,
              numericality: { greater_than_or_equal_to: 0,
                              less_than_or_equal_to: 100 },
              allow_nil: true
    validates :min_points_absolute,
              numericality: { greater_than_or_equal_to: 0 },
              allow_nil: true
    validate :percentage_or_absolute_not_both
    validate :threshold_value_required_for_mode

    def rule_achievement_ids_set
      Set.new(rule_achievements.pluck(:achievement_id))
    end

    private

      def percentage_or_absolute_not_both
        return unless min_percentage.present? && min_points_absolute.present?

        errors.add(:base, :percentage_and_absolute_exclusive)
      end

      def threshold_value_required_for_mode
        return if threshold_mode.blank?

        if threshold_mode == "percentage" && min_percentage.nil?
          errors.add(:min_percentage, :blank)
        elsif threshold_mode == "absolute" && min_points_absolute.nil?
          errors.add(:min_points_absolute, :blank)
        end
      end
  end
end
