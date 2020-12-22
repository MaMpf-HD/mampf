# frozen_string_literal: true

FactoryBot.define do
  factory :announcement do
    association :announcer, factory: :confirmed_user
    details { Faker::TvShows::GameOfThrones.quote }

    trait :with_lecture do
      association :lecture
      after(:build) do |announcement|
        announcement.announcer = announcement.lecture.teacher
      end
    end
  end
end
