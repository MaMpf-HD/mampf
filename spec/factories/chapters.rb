# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :chapter do
    association :lecture, factory: [:lecture]
    title { Faker::Book.title + ' ' +
              Faker::Number.between(from: 1, to: 9999).to_s }

    transient do
      section_count { 3 }
    end

    trait :with_sections do
      after(:build) do |chapter, evaluator|
        chapter.sections = create_list(:section, evaluator.section_count)
      end
    end
  end
end
