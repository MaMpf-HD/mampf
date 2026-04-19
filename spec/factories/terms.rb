require "faker"

FactoryBot.define do
  factory :term do
    season { ["WS", "SS"].sample }
    year { Faker::Number.between(from: 2000, to: 2100) }

    trait :summer do
      season { "SS" }
    end

    trait :winter do
      season { "WS" }
    end

    trait :active do
      active { true }
    end
  end
end
