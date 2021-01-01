# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :tag, aliases: [:related_tag] do
    transient do
      notions_count { 1 }
      related_tags_count { 2 }
      courses_count { 2 }
      title do
        Faker::Book.title + ' ' + Faker::Number.between(from: 1, to: 9999).to_s
      end
    end

    after(:build) do |tag, evaluator|
      tag.notions << build(:notion, title: evaluator.title)
    end

    trait :with_several_notions do
      after(:build) do |tag, evaluator|
        tag.notions = build_list(:notion, evaluator.notions_count)
      end
    end

    trait :with_related_tags do
      after(:build) do |tag, evaluator|
        tag.related_tags = build_list(:tag, evaluator.related_tags_count)
      end
    end

    trait :with_courses do
      after(:build) do |tag, evaluator|
        tag.courses = build_list(:course, evaluator.courses_count)
      end
    end
  end
end
