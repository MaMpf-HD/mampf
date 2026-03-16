module StudentPerformance
  class Rule < ApplicationRecord
    belongs_to :lecture

    has_many :rule_achievements,
             class_name: "StudentPerformance::RuleAchievement",
             dependent: :destroy
    has_many :required_achievements,
             through: :rule_achievements,
             source: :achievement

    validates :min_percentage,
              numericality: { greater_than_or_equal_to: 0,
                              less_than_or_equal_to: 100 },
              allow_nil: true
    validates :min_points_absolute,
              numericality: { greater_than_or_equal_to: 0 },
              allow_nil: true
    validate :percentage_or_absolute_not_both

    private

      def percentage_or_absolute_not_both
        return unless min_percentage.present? && min_points_absolute.present?

        errors.add(:base, :percentage_and_absolute_exclusive)
      end
  end
end
