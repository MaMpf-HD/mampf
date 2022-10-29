# frozen_string_literal: true

FactoryBot.define do
  factory :lesson_tag_join do
    association :lesson
    association :tag
  end
end
