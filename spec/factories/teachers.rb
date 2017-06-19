FactoryGirl.define do
  factory :teacher do
    sequence(:name) { |n| "Test Teacher #{n}" }
    sequence(:email) { |n| "teacher#{n}@example.com" }
  end
end
