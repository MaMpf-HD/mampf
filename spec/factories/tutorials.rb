# frozen_string_literal: true

FactoryBot.define do
  factory :tutorial do
    association :lecture
    title { Faker::Movie.title + ' ' + Faker::Number.number.to_s }
  end

  trait :with_tutors do
    transient do
      tutors_count { 1 }
    end
    after :build do |t, evaluator|
      t.tutors = build_list(:confirmed_user, evaluator.tutors_count)
    end
  end
end
