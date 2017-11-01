FactoryGirl.define do
  factory :user do
    email { Faker::Internet.email }
    password {Faker::Internet.password}
    subscription_type Random.rand(1..3)
    sign_in_count Random.rand(5..10)
    after(:build) { |user| user.lectures = create_list(:lecture, 2) }
  end
end
