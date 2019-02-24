require 'faker'

FactoryBot.define do
  factory :term do
    # season 'WS'
    year { Faker::Number.between(2000, 100000) }
    #trait :summer do
    #  season 'SS'
    #end
  end
end
