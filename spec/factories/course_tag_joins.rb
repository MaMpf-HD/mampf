# frozen_string_literal: true

FactoryBot.define do
  factory :course_tag_join do
    association :tag
    association :course
  end
end
