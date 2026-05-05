FactoryBot.define do
  factory :exam do
    association :lecture
    title { "Exam #{Faker::Number.number(digits: 4)}" }

    trait :with_date do
      date { Faker::Time.forward(days: 30) }
    end

    trait :oral do
      date { nil }
      location { nil }
    end

    trait :with_capacity do
      capacity { Faker::Number.between(from: 50, to: 200) }
    end
  end
end