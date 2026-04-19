FactoryBot.define do
  factory :assignment do
    title do
      Faker::Marketing.buzzwords +
        Faker::Number.between(from: 1, to: 9999).to_s
    end
    deadline { Faker::Time.forward(days: 30) }
    accepted_file_type { ".pdf" }

    trait :with_lecture do
      association :lecture, :released_for_all
    end

    trait :inactive do
      deadline { Faker::Time.backward(days: 30) }

      to_create do |instance|
        instance.save!(validate: false)
      end
    end

    trait :expired do
      transient do
        expired_since { 1.day }
      end

      after(:create) do |assignment, evaluator|
        past_deadline = evaluator.expired_since.ago
        assignment.update_column(:deadline, past_deadline)
      end
    end

    factory :valid_assignment, traits: [:with_lecture]
  end
end
