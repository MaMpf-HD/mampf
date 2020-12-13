require 'faker'

FactoryBot.define do
  factory :chapter do
    association :lecture, factory: [:lecture]
    title { Faker::Book.title + ' ' +
              Faker::Number.between(from: 1, to: 99).to_s }

    transient do
      section_count { 3 }
    end

    trait :with_sections do
      after(:build) do |chapter, evaluator|
        chapter.sections = build_list(:section, evaluator.section_count)
      end
    end
  end
end
