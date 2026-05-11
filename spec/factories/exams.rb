FactoryBot.define do
  factory :exam do
    association :lecture
    title { "#{Faker::Educator.subject} Exam #{Faker::Number.number(digits: 4)}" }

    trait :with_date do
      date { Faker::Time.forward(days: 30) }
    end

    trait :written do
      with_date
      location { Faker::University.name }
    end

    trait :oral do
      date { nil }
      location { nil }
    end

    trait :with_capacity do
      capacity { Faker::Number.between(from: 50, to: 200) }
    end

    trait :unlimited do
      capacity { nil }
    end
  end
end
