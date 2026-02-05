FactoryBot.define do
  factory :exam_roster do
    association :exam
    association :user, factory: :confirmed_user
    source_campaign { nil }

    trait :from_campaign do
      association :source_campaign, factory: :registration_campaign
    end
  end
end
