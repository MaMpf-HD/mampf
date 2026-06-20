FactoryBot.define do
  factory :cohort do
    sequence(:title) { |n| "Repeaters Linear Algebra #{n}" }
    description do
      "If you failed last year's exam and don't want to go through tutorials again, register here."
    end
    capacity { nil }
    propagate_to_lecture { false }
    association :context, factory: :lecture

    trait :enrollment do
      propagate_to_lecture { true }
    end

    trait :planning do
      propagate_to_lecture { false }
    end
  end
end
