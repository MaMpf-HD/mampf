# frozen_string_literal: true

FactoryBot.define do
  factory :clicker do
    title { Faker::Book.title + Faker::Number.between(from: 1, to: 9999).to_s }

    transient do
      alternative_count { 3 }
    end

    trait :with_editor do
      association :editor, factory: :confirmed_user
    end

    trait :with_question do
      association :question
    end

    trait :open do
      open { true }
    end

    trait :with_modified_alternatives do
      after :create do |clicker, evaluator|
        clicker.alternatives = evaluator.alternative_count
      end
    end

    factory :valid_clicker, traits: [:with_editor]
  end
end
