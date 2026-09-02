FactoryBot.define do
  factory :term do
    # Year and season are unique together, so they are counted out rather than
    # drawn: two random draws that match make an unrelated example fail.
    transient do
      sequence(:index)
    end

    season { index.even? ? "SS" : "WS" }
    year { 2000 + index }

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
