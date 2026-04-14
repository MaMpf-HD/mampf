FactoryBot.define do
  factory :tutorial_membership do
    association :user
    association :tutorial, strategy: :create
    source_campaign { nil }
  end
end
