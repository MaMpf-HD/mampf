# frozen_string_literal: true

FactoryBot.define do
  factory :assignment do
    title { Faker::Marketing.buzzwords +
            Faker::Number.between(from: 1, to: 9999).to_s}
    deadline { Faker::Time.forward(days: 30) }
    accepted_file_type { '.pdf' }

    trait :with_lecture do
      association :lecture, :released_for_all
    end

    factory :valid_assignment, traits: [:with_lecture]
  end
end
