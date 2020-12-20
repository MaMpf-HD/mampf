FactoryBot.define do
  factory :lecture_user_join do
    association :lecture
    association :user, factory: :confirmed_user
  end
end