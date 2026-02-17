FactoryBot.define do
  factory :cohort do
    title { "Repeaters Linear Algebra 1" }
    description do
      "If you failed last year's exam and don't want to go through tutorials again, register here."
    end
    capacity { nil }
    purpose { :general }
    propagate_to_lecture { false }
    association :context, factory: :lecture

    trait :general do
      purpose { :general }
      propagate_to_lecture { false }
    end

    trait :enrollment do
      purpose { :enrollment }
      propagate_to_lecture { true }
    end

    trait :planning do
      purpose { :planning }
      propagate_to_lecture { false }
    end
  end
end
