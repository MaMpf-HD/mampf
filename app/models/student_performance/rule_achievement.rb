module StudentPerformance
  class RuleAchievement < ApplicationRecord
    belongs_to :rule, class_name: "StudentPerformance::Rule"
    belongs_to :achievement

    validates :rule_id, uniqueness: { scope: :achievement_id }
    validates :position, presence: true

    acts_as_list scope: :rule
  end
end
