FactoryBot.define do
  factory :lecture_bookmark do
    association :lecture
    association :user, factory: :confirmed_user
  end
end
