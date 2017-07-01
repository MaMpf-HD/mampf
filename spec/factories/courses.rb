FactoryGirl.define do
  factory :course do
    title { Faker::Book.title }
    trait :with_tags do
      after(:build) { |course| course.tags = create_list(:tag, 2) }
    end
  end
end
