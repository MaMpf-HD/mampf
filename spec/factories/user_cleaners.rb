FactoryBot.define do
  factory :user_cleaner do
    # trait with user
    trait :with_mail do
      after(:build) do |c|
        user = FactoryBot.create(:confirmed_user, email: Faker::Internet.email)
        c.email_dict = { user.email => [] }
      end
    end
  end
end
