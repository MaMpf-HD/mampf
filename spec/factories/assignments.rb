FactoryBot.define do
  factory :assignment do
    title do
      Faker::Marketing.buzzwords +
        Faker::Number.between(from: 1, to: 9999).to_s
    end
    deadline { Faker::Time.forward(days: 30) }
    deletion_date { Faker::Date.forward(days: 60) }
    accepted_file_type { ".pdf" }

    trait :with_lecture do
      association :lecture, :released_for_all
    end

    trait :inactive do
      deadline { Faker::Time.backward(days: 30) }
    end

    factory :valid_assignment, traits: [:with_lecture]
  end
end
