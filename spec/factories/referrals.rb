# frozen_string_literal: true

FactoryBot.define do
  factory :referral do
    association :item
    association :medium

    transient do
      start_time_in_s { Faker::Number.decimal(l_digits: 4, r_digits: 3) }
      end_time_in_s do
        start_time_in_s + Faker::Number.decimal(l_digits: 3, r_digits: 3)
      end
    end

    trait :with_times do
      after :build do |r, evaluator|
        r.start_time = build(:time_stamp,
                             total_seconds: evaluator.start_time_in_s)
        r.end_time = build(:time_stamp,
                           total_seconds: evaluator.end_time_in_s)
      end
    end

    factory :referral_for_sample_video, traits: [:with_times] do
      transient do
        start_time_in_s { Faker::Number.between(from: 0, to: 30_000) / 1000.0 }
        end_time_in_s do
          start_time_in_s + Faker::Number.between(from: 1, to: 10)
        end
      end
      medium { association :valid_medium, :with_video }
    end
  end
end
