require 'faker'

FactoryGirl.define do
  factory :learning_asset do
    title { Faker::ChuckNorris.fact }
    heading { Faker::Book.title }
    association :teachable, factory: [:lesson, :with_tags]
    trait :for_lecture do
      association :teachable, factory: :lecture
    end
    trait :for_course do
      association :teachable, factory: [:course, :with_tags]
    end
    after(:build) do |l|
      l.tags = l.teachable.tags.sample(2)
      l.media = create_list(:medium, 2)
    end
  end
end
