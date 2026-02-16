FactoryBot.define do
  factory :watchlist do
    name { Faker::Movie.title }

    transient do
      user { nil }
    end

    before(:create) do |watchlist, evaluator|
      next if evaluator.user.blank?

      if evaluator.user.is_a?(Hash)
        watchlist.user_id = evaluator.user["id"]
      elsif evaluator.user.is_a?(Integer)
        watchlist.user_id = evaluator.user
      else
        watchlist.user = evaluator.user
      end
    end

    trait :with_user do
      user { create(:confirmed_user) }
    end
  end
end
