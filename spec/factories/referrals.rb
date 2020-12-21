FactoryBot.define do
  factory :referral do
    association :item
    association :medium

    trait :with_times do
      transient do
        start_time_in_s { Faker::Number.decimal(l_digits: 4, r_digits: 3) }
        end_time_in_s { start_time_in_s +
                        Faker::Number.decimal(l_digits: 3, r_digits: 3)}
      end
      after :build do |r, evaluator|
        r.start_time = build(:time_stamp,
                             total_seconds: evaluator.start_time_in_s)
        r.end_time = build(:time_stamp,
                           total_seconds: evaluator.end_time_in_s)
      end
    end
  end
end
