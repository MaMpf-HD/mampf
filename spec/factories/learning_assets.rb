require 'faker'

FactoryGirl.define do
  factory :learning_asset, aliases: [:linked_asset] do
    sort %w[KaviarAsset ErdbeereAsset SesamAsset ResteAsset].sample
    title { Faker::ChuckNorris.fact + ' ' + Faker::Number.between(1,99).to_s}
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
