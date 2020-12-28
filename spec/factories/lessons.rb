# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :lesson do
    # the generic factory for lesson will just produce an empty lesson
    # as it is rather expensive to build a valid lesson from scratch
    # (and in most tests you will probably start with an empty lesson and
    # add an already existing lecture etc.)
    # if you want a valid lesson with all that is needed use the valid_lesson
    # factory
    trait :with_lecture_and_date do
      association :lecture, factory: :lecture_with_sparse_toc
      date { Faker::Date.between(from: lecture.term.begin_date,
                                 to: lecture.term.end_date) }
    end

    trait :with_lecture_date_and_section do
      with_lecture_and_date
      after(:build) do |lesson|
        lesson.sections << lesson.lecture.chapters.first.sections.first
      end
    end

    factory :valid_lesson, traits: [:with_lecture_date_and_section]
  end
end
