FactoryBot.define do
  factory :watchlist_entry do
    watchlist { nil }
    medium { nil }
    medium_position { 1 }

    trait :with_watchlist do
      watchlist { create(:watchlist, user_id: 1) }
    end

    trait :with_medium do
      medium { create(:lecture_medium, :released) }
    end
  end
end
