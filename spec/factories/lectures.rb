FactoryBot.define do
  factory :lecture, aliases: [:preceding_lecture] do
    association :course, factory: [:course, :with_tags]
    association :teacher
    association :term
    trait :with_disabled_tags do
      after(:build) { |l| l.disabled_tags = l.course.tags.sample(2) }
    end
    trait :with_additional_tags do
      after(:build) { |l| l.additional_tags = create_list(:tag, 2) }
    end
  end
end
