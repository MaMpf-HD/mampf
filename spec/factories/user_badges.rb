FactoryBot.define do
  factory :user_badge do
    user { factory :confirmed_user }
    badge { factory :badge, :comments }
  end
end
