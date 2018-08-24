FactoryBot.define do
  factory :user, aliases: [:teacher] do
    email { Faker::Internet.email }
    password {Faker::Internet.password}
    subscription_type Faker::Number.between(1, 3)
    consents true
    name Faker::Name.name
    trait :with_lectures do
      after(:build) { |user| user.lectures = FactoryBot.create_list(:lecture, 2) }
    end
  end
end
