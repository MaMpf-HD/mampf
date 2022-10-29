# frozen_string_literal: true

FactoryBot.define do
  factory :interaction do
    trait :with_stuff do
      session_id { Faker::Crypto.md5 }
      referrer_url { Faker::Internet.url }
      full_path { Faker::Internet.url }
    end
  end
end
