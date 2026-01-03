FactoryBot.define do
  factory :cohort_membership do
    association :user
    association :cohort
    source_campaign { nil }
  end
end
