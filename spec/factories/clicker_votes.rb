# frozen_string_literal: true

FactoryBot.define do
  factory :clicker_vote do
    value { [1, 2, 3].sample }

    trait :with_clicker do
      # this is done instead of an association since clicker has a
      # before_create callback
      after :build do |vote|
        vote.clicker = create(:valid_clicker, :open)
      end
    end

    factory :valid_clicker_vote, traits: [:with_clicker]
  end
end
