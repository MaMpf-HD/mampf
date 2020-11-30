require 'faker'

FactoryBot.define do
  factory :notion, aliases: [:related_notion] do
    locale { ['de', 'en'].sample }
    title { Faker::Book.title + ' ' +
            Faker::Number.between(from: 1, to: 9999).to_s }
    trait :with_tag do
      after(:build) { |t| t.tag = build(:tag) }
    end
  end
end
