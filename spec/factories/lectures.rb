FactoryGirl.define do
  factory :lecture do
    association :course, factory: [:course, :with_tags]
    association :teacher
    association :term
    trait :with_disabled_tags do
      after(:build) { |l| l.disabled_tags = create_list(:tag, 2) }
    end
  end
end
