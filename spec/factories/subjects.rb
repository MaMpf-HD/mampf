# frozen_string_literal: true

FactoryBot.define do
  factory :subject do
    name { Faker::IndustrySegments.super_sector }
  end
end
