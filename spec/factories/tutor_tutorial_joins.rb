FactoryBot.define do
  factory :tutor_tutorial_join do
    association :tutorial
    association :tutor, factory: :confirmed_user
  end
end
