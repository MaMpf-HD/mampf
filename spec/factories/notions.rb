require 'faker'

FactoryBot.define do
  factory :notion, aliases: [:realated_notion] do
    locale { "de"}
    sequence(:title) { |n| "notionNr.#{n}" }
    #association :tag, factory: :tag
    trait :with_tag do
      after(:build) { |t| t.tag = build(:tag) }
    end
    trait :with_specified_tag do
      tag_id {1}
    end
    trait :with_aliased_tag do
      aliased_tag_id {2}
    end
  end
end
