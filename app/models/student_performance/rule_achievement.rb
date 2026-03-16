module StudentPerformance
  class RuleAchievement < ApplicationRecord
    belongs_to :rule, class_name: "StudentPerformance::Rule", touch: true
    belongs_to :achievement

    validates :rule_id, uniqueness: { scope: :achievement_id }
    validates :position, presence: true
    validate :same_lecture

    acts_as_list scope: :rule

    private

      def same_lecture
        return unless rule && achievement
        return if rule.lecture_id == achievement.lecture_id

        errors.add(:achievement, :must_belong_to_same_lecture)
      end
  end
end
