FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password {Faker::Internet.password}
    subscription_type Faker::Number.between(1, 3)
    sign_in_count Faker::Number.between(5, 10)
    after(:build) { |user| user.lectures = FactoryBot.create_list(:lecture, 2) }
  end
end
