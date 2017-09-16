require 'faker'

FactoryGirl.define do
  factory :asset, aliases: [:linked_asset] do
    sort %w[Kaviar Erdbeere Sesam Reste].sample
    title { Faker::ChuckNorris.fact + ' ' + Faker::Number.between(1, 99).to_s }
    heading { Faker::Book.title }
    association :teachable, factory: [:lesson, :with_tags]
    trait :for_lecture do
      association :teachable, factory: :lecture
    end
    trait :for_course do
      association :teachable, factory: [:course, :with_tags]
    end
    after(:build) do |l|
      l.media = create_list(:medium, 2)
    end
  end
end
