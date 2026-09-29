FactoryBot.define do
  factory :student_performance_rule,
          class: "StudentPerformance::Rule" do
    association :lecture, factory: :lecture
    active { false }
    # Most specs are about the threshold, so the default carries one.
    threshold_mode { :percentage }
    min_percentage { 50 }

    trait :with_percentage do
      threshold_mode { :percentage }
      min_percentage { 50 }
    end

    trait :with_absolute_points do
      threshold_mode { :absolute }
      min_percentage { nil }
      min_points_absolute { 60 }
    end

    trait :without_criteria do
      threshold_mode { :none }
      min_percentage { nil }
      min_points_absolute { nil }
    end

    trait :active do
      active { true }
    end
  end
end
