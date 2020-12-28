# frozen_string_literal: true

FactoryBot.define do
  factory :answer do
    trait :with_question do
      after(:build) do |answer|
        answer.question = build(:valid_question)
      end
    end

    trait :with_stuff do
      text { Faker::Lorem.sentence }
      value { [true, false].sample }
      explanation { Faker::Lorem.sentence }
    end

    factory :valid_answer, traits: [:with_question]
  end
end
