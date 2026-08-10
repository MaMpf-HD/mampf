FactoryBot.define do
  factory :lecture_membership do
    association :user
    association :lecture
    source_campaign { nil }
  end
end
