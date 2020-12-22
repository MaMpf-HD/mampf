# frozen_string_literal: true

FactoryBot.define do
  factory :submission do
    transient do
      lecture { build(:lecture) }
      users_count { 2 }
    end

    trait :with_assignment do
      assignment { association :assignment, lecture: lecture }
    end

    trait :with_tutorial do
      tutorial { association :tutorial, lecture: lecture }
    end

    trait :with_users do
      after :build do |s, evaluator|
        s.users = build_list(:confirmed_user, evaluator.users_count)
      end
    end

    factory :valid_submission, traits: [:with_assignment, :with_tutorial]
  end
end
