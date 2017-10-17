FactoryGirl.define do
  factory :lecture do
    association :course, factory: [:course, :with_tags]
    association :teacher
    association :term
    kaviar [true, false].sample
    keks [true, false].sample
    sesam [true, false].sample
    erdbeere [true, false].sample
    reste [true, false].sample
    kiwi [true,false].sample
    trait :with_disabled_tags do
      after(:build) { |l| l.disabled_tags = l.course.tags.sample(2) }
    end
    trait :with_additional_tags do
      after(:build) { |l| l.additional_tags = create_list(:tag, 2) }
    end
    # trait :with_lessons do
    #   after(:build) { |l| l.lessons = create_list(:lesson, 3) }
    # end
  end
end
