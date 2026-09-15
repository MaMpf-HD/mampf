FactoryBot.define do
  factory :exam_roster_entry do
    association :exam
    association :user, factory: :confirmed_user
    source_campaign { nil }

    trait :from_campaign do
      association :source_campaign, factory: :registration_campaign
    end
  end
end
