# frozen_string_literal: true

FactoryBot.define do
  factory :submission_cleaner do
    transient do
      date { Faker::Date.forward(days: 365) }
    end

    initialize_with do
      new(date: date)
    end
  end
end