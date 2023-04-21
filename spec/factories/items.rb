# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    sort { ['remark', 'example', 'theorem', 'definition'].sample }

    transient do
      starting_time { Faker::Number.decimal(l_digits: 4, r_digits: 3) }
    end

    trait :with_start_time do
      after :build do |i, evaluator|
        i.start_time = build(:time_stamp,
                             total_seconds: evaluator.starting_time)
      end
    end

    trait :with_medium do
      medium { association :valid_medium, :with_video }
    end

    factory :item_for_sample_video, traits: [:with_start_time, :with_medium] do
      transient do
        starting_time { Faker::Number.between(from: 0, to: 42_770) / 1000.0 }
      end
    end
  end
end
