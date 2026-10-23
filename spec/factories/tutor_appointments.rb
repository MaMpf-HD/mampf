FactoryBot.define do
  factory :tutor_appointment do
    association :lecture
    association :user, factory: :confirmed_user
  end
end
