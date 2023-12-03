# frozen_string_literal: true

FactoryBot.define do
  factory :time_stamp do
    transient do
      total_seconds { Faker::Number.decimal(l_digits: 4, r_digits: 3) }
    end

    initialize_with { new(total_seconds: total_seconds) }

    # call it like this:
    # FactoryBot.build(:time_stamp_by_string, time_string: '1:17:29.745')
    factory :time_stamp_by_string do
      transient do
        time_string { '0:00:00.000' }
      end
      initialize_with { new(time_string: time_string) }
    end

    # call it like this:
    # FactoryBot.build(:time_stamp_by_hms, h: 1, m: 17, s: 29, ms: 745)
    factory :time_stamp_by_hms do
      transient do
        h { 0 }
        m { 0 }
        s { 0 }
        ms { 0 }
      end
      initialize_with { new(h: h, m: m, s: s, ms: ms) }
    end
  end
end
