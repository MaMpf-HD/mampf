FactoryBot.define do
  factory :user_cleaner do
    # trait with user
    trait :with_hashed_user do
      after(:build) do |c|
        user = FactoryBot.create(:confirmed_user, email: Faker::Internet.email)
        user.update(ghost_hash: Digest::SHA256.hexdigest(Time.now.to_i.to_s))
        c.email_dict = {}
        c.hash_dict = { user.email => user.ghost_hash }
      end
    end
  end
end
