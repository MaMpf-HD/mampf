# frozen_string_literal: true

FactoryBot.define do
  factory :division_course_join do
    association :division
    association :course
  end
end
