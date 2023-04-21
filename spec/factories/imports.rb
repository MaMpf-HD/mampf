# frozen_string_literal: true

FactoryBot.define do
  factory :import do
    transient do
      teachable_sort { :lecture }
    end

    trait :with_teachable do
      after(:build) do |i, evaluator|
        i.teachable = if evaluator.teachable_sort == :course
          build(:course)
        elsif evaluator.teachable_sort == :lecture
          build(:lecture)
        else
          build(:valid_lesson)
        end
      end
    end

    trait :with_medium do
      association :medium, factory: :valid_medium
    end

    factory :valid_import, traits: [:with_teachable, :with_medium]
  end
end
