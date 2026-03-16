FactoryBot.define do
  factory :student_performance_rule,
          class: "StudentPerformance::Rule" do
    association :lecture, factory: :lecture
    active { false }

    trait :with_percentage do
      min_percentage { 50 }
    end

    trait :with_absolute_points do
      min_points_absolute { 60 }
    end

    trait :active do
      active { true }
    end
  end
end
