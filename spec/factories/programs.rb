# frozen_string_literal: true

FactoryBot.define do
  factory :program do
    association :subject
    name { Faker::IndustrySegments.sector }
  end
end
