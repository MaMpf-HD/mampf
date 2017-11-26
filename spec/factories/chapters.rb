require 'faker'

FactoryBot.define do
  factory :chapter do
    association :lecture, factory: [:lecture, :with_disabled_tags,
                                    :with_additional_tags]
    title { Faker::Book.title + ' ' + Random.rand(1..99).to_s }
    number { Faker::Number.between(1, 999) }
    trait :with_sections do
      after(:build) { |c| c.sections = create_list(:section, 3) }
    end
  end
end
