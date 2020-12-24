# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :medium do
    # the generic factory for medium will just produce an empty medium
    # as it is rather expensive to build a valid medium from scratch
    # (and in most tests you will probably start with an empty medium and
    # add an already existing teachable etc.)
    # if you want a valid medium with all that is needed use the valid_medium
    # factory (for a medium at lecture level), or the lesson_medium or
    # course_medium factories

    transient do
      teachable_sort { :lecture }
      tags_count { 2 }
      linked_media_count { 2 }
      editors_count { 1 }
      prescribed_teachable { build(teachable_sort) }
    end

    trait :with_description do
      description { Faker::Restaurant.name }
    end

    trait :with_editors do
      after(:build) do |m, evaluator|
        m.editors = build_list(:confirmed_user, evaluator.editors_count)
      end
    end

    trait :with_tags do
      after(:build) do |m, evaluator|
        m.tags = build_list(:tag, evaluator.tags_count)
      end
    end

    trait :with_linked_media do
      after(:build) do |m, evaluator|
        m.linked_media = build_list(:valid_medium, evaluator.linked_media_count)
      end
    end

    trait :with_teachable do
      teachable { prescribed_teachable }
    end

    trait :with_manuscript do
      after(:build) do |m|
        m.manuscript = File.open('spec/files/manuscript.pdf', 'rb')
      end
    end

    trait :with_video do
      after(:build) do |m|
        m.video = File.open('spec/files/talk.mp4', 'rb')
      end
    end

    factory :lesson_medium,
            traits: [:with_description, :with_teachable] do
      sort { 'Kaviar' }
      teachable_sort { :valid_lesson }
      after(:build) { |m| m.editors << m.teachable.lecture.teacher }
    end

    factory :lecture_medium,
            traits: [:with_description, :with_teachable],
            aliases: [:valid_medium] do
      sort { 'Sesam' }
      after(:build) { |m| m.editors << m.teachable.teacher }
    end

    factory :course_medium,
            traits: [:with_description, :with_teachable, :with_editors] do
      sort { 'Sesam' }
      teachable_sort { :course }
    end
  end
end
