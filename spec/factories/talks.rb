# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :talk do
    # the generic factory for lesson will just produce an empty talk
    # as it is rather expensive to build a valid lesson from scratch
    # (and in most tests you will probably start with an empty talk and
    # add an already existing lecture etc.)
    # if you want a valid talk with all that is needed use the valid_talk
    # factory

    title do
      Faker::Book.title + ' ' + Faker::Number.between(from: 1, to: 9999).to_s
    end

    trait :with_seminar do
      association :lecture, factory: :seminar
    end

    trait :with_date
      dates do
        [ Faker::Date.in_date_period ]
    end

    trait :with_speaker do
      after(:build) do |t|
        speaker = build(:confirmed_user)
        t.speakers << speaker
      end
    end

    factory :valid_talk, traits: [:with_seminar]

    factory :valid_talk_with_speaker, traits: [:with_seminar, :with_speaker]
  end
end