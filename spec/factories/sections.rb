# frozen_string_literal: true

FactoryBot.define do
  factory :section do
    association :chapter
    title { Faker::Book.title + ' ' +
              Faker::Number.between(from: 1, to: 9999).to_s }
  end
end
