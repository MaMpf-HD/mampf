# frozen_string_literal: true

FactoryBot.define do
  factory :consumption do
    trait :with_stuff do
      medium_id { Faker::Number.number }
      sort { ['video', 'manuscript'].sample }
      after :build do |consumption|
        if consumption.sort == 'video'
          consumption.mode = ['thyme', 'download'].sample
        else
          consumption.mode = ['pdf_view', 'download'].sample
        end
      end
    end
  end
end
