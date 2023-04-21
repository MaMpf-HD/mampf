# frozen_string_literal: true

FactoryBot.define do
  factory :consumption do
    trait :with_stuff do
      medium_id { Faker::Number.number }
      sort { ['video', 'manuscript'].sample }
      after :build do |consumption|
        consumption.mode = if consumption.sort == 'video'
          ['thyme', 'download'].sample
        else
          ['pdf_view', 'download'].sample
        end
      end
    end
  end
end
