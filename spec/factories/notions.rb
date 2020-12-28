# frozen_string_literal: true

require 'faker'

FactoryBot.define do
  factory :notion, aliases: [:related_notion] do
    # to get a valid notion, a tag has to be added
    # in order to avoid loops in the creation of tags (which need a notion)
    # the adding of a tag is done in the valid_notion factory
    locale { 'de' }
    title { Faker::Book.title + ' ' +
            Faker::Number.between(from: 1, to: 9999).to_s }

    trait :with_tag do
      after(:build) { |t| t.tag = build(:tag) }
    end

    factory :valid_notion, traits: [:with_tag]
  end
end
