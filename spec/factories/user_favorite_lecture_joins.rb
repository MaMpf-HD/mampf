# frozen_string_literal: true

FactoryBot.define do
  factory :user_favorite_lecture_join do
    association :user, factory: :confirmed_user
    association :lecture
  end
end
