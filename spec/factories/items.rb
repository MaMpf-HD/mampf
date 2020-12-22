# frozen_string_literal: true

FactoryBot.define do
  factory :item do
    sort { ['remark', 'example', 'theorem', 'definition'].sample }

    trait :with_start_time do
      after :build do |i|
        i.start_time = build(:time_stamp)
      end
    end

    trait :with_medium do
      association :medium, factory: :valid_medium
    end
  end
end
