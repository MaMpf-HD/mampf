# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :term do
    season { ['WS', 'SS'].sample }
    year { Faker::Number.between(from: 2000, to: 100000) }

    trait :summer do
      season  { 'SS' }
    end
  end
end
