FactoryBot.define do
  factory :term do
    # Year and season are unique together, so they are counted out rather than
    # drawn: two random draws that match make an unrelated example fail.
    transient do
      sequence(:index)
    end

    season { index.even? ? "SS" : "WS" }
    # Steps over a term an example has already created with an explicit year.
    year do
      counted = 2000 + index
      counted += 1 while Term.exists?(season: season, year: counted)
      counted
    end

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
