# frozen_string_literal: true

FactoryBot.define do
  factory :lesson_section_join do
    association :lesson
    association :section
  end
end
