FactoryBot.define do
  factory :student_performance_rule,
          class: "StudentPerformance::Rule" do
    association :lecture, factory: :lecture
    active { false }
    # A rule must constrain something, so the default carries a threshold.
    min_percentage { 50 }

    trait :with_percentage do
      min_percentage { 50 }
    end

    trait :with_absolute_points do
      min_percentage { nil }
      min_points_absolute { 60 }
    end

    trait :without_criteria do
      min_percentage { nil }
      min_points_absolute { nil }
    end

    trait :active do
      active { true }
    end
  end
end
