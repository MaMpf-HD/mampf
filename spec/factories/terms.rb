require "faker"

FactoryBot.define do
  factory :term do
    season { ["WS", "SS"].sample }
    sequence(:year) { |n| 1999 + n }

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
