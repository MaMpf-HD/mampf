class Achievement < ApplicationRecord
  belongs_to :lecture

  has_many :rule_achievements,
           class_name: "StudentPerformance::RuleAchievement",
           dependent: :restrict_with_error

  enum :value_type, { boolean: 0, numeric: 1, percentage: 2 }

  validates :title, :value_type, presence: true
  validates :threshold,
            numericality: { greater_than: 0 },
            if: :numeric?
  validates :threshold,
            numericality: { greater_than_or_equal_to: 0,
                            less_than_or_equal_to: 100 },
            if: :percentage?
  validates :threshold, absence: true, if: :boolean?
end
