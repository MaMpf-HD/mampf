FactoryBot.define do
  factory :watchlist do
    user { nil }
    name { Faker::Movie.title }

    trait :with_user do
      user { create(:confirmed_user) }
    end
  end
end
