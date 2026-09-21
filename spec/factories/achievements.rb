FactoryBot.define do
  factory :achievement do
    association :lecture, factory: :lecture
    title { "Blackboard Presentation" }
    value_type { :boolean }
    threshold { nil }

    trait :boolean do
      value_type { :boolean }
      threshold { nil }
    end

    trait :numeric do
      title { "Lab Attendance" }
      value_type { :numeric }
      threshold { 12 }
    end

    trait :percentage do
      title { "Lab Participation" }
      value_type { :percentage }
      threshold { 75.0 }
    end

    trait :with_assessment do
      after(:create) do |achievement|
        achievement.ensure_assessment!(
          requires_points: false,
          requires_submission: false
        )
      end
    end
  end
end
