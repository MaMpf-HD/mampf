require 'faker'

FactoryGirl.define do
  factory :tag, aliases: [:related_tag] do
    title { Faker::StarWars.quote }
    trait :with_related_tags do
      after(:build) { |t| t.related_tags = create_list(:tag, 2) }
    end
  end
end
