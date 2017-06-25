require 'faker'

FactoryGirl.define do
  factory :teacher do
    name { Faker::StarWars.character }
    email { Faker::Internet.email }
  end
end
