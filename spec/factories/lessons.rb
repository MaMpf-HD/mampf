require 'faker'

FactoryBot.define do
  factory :lesson do
    association :lecture, factory: [:lecture, :with_disabled_tags,
                                    :with_additional_tags]
    date { Faker::Date.between(lecture.term.begin_date, lecture.term.end_date) }
    number { Faker::Number.between(1, 999) }
    trait :with_tags do
      after(:build) { |l| l.tags = [l.lecture.tags.sample] }
    end
  end
end
