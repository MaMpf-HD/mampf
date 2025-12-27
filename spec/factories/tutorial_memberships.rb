FactoryBot.define do
  factory :tutorial_membership do
    association :user
    association :tutorial
    source_campaign { nil }
  end
end
