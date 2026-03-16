FactoryBot.define do
  factory :student_performance_rule_achievement,
          class: "StudentPerformance::RuleAchievement" do
    rule { association :student_performance_rule }
    achievement { association :achievement, lecture: rule&.lecture }
    position { 1 }
  end
end
