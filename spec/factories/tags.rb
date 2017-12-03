require 'faker'

FactoryBot.define do
  factory :tag, aliases: [:related_tag] do
    title { Faker::Company.bs + ' ' + Faker::Number.between(1, 9999).to_s }
    trait :with_related_tags do
      after(:build) { |t| t.related_tags = create_list(:tag, 2) }
    end
    trait :with_courses do
      after(:build) { |t| t.courses = create_list(:course, 2) }
    end
  end
end
