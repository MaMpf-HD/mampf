require 'faker'

FactoryGirl.define do
  factory :teacher do
    name { Faker::Name.name }
    email { Faker::Internet.email }
  end
end
