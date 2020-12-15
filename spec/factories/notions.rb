require 'faker'

FactoryBot.define do
  factory :notion, aliases: [:realated_notion] do
    locale { 'de' }
    title { Faker::Educator.subject + ' ' + Faker::Number.between(from: 1, to: 999).to_s }
    # association :tag, factory: :tag
    trait :with_tag do
      after(:build) { |t| t.tag = build(:tag) }
    end
    trait :with_specified_tag do
      tag_id { 1 }
    end
    trait :with_aliased_tag do
      aliased_tag_id { 2 }
    end
  end
end
