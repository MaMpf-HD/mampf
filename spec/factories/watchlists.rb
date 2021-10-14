FactoryBot.define do
  factory :watchlist do
    user { nil }
    name { Faker::Movie.title }
  end
end
