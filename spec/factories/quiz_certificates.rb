# frozen_string_literal: true

FactoryBot.define do
  factory :quiz_certificate do
    association :quiz

    trait :with_user do
      association :user, factory: :confirmed_user
    end

    trait :with_valid_quiz do
      association :quiz, factory: :valid_quiz
    end
  end
end
