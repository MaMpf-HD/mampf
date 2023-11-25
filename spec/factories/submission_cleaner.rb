# frozen_string_literal: true

FactoryBot.define do
  factory :submission_cleaner do
    transient do
      date { Time.zone.today }
    end

    initialize_with do
      new(date:)
    end
  end
end
