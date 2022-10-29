# frozen_string_literal: true

FactoryBot.define do
  factory :user_submission_join do
    association :user
    association :submission, factory: :valid_submission
  end
end
