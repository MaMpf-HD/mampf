# frozen_string_literal: true

FactoryBot.define do
  factory :editable_user_join do
    association :user, factory: :confirmed_user
    association :editable, factory: :medium

    trait :with_course do
      association :editable, factory: :course
    end

    trait :with_lecture do
      association :editable, factory: :lecture
    end
  end
end
