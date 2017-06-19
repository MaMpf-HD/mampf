FactoryGirl.define do
  factory :course do
    sequence(:title) { |n| "Test Course #{n}" }
    trait :with_tags do
      after(:build) { |course| course.tags = create_list(:tag, 2) }
    end
  end
end
