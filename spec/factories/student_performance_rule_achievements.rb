FactoryBot.define do
  factory :student_performance_rule_achievement,
          class: "StudentPerformance::RuleAchievement" do
    association :rule, factory: :student_performance_rule
    association :achievement
    position { 1 }
  end
end
