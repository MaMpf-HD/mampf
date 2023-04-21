# frozen_string_literal: true

FactoryBot.define do
  factory :course_self_join do
    association :course
    association :preceding_course, factory: :course
  end
end
