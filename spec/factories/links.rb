# frozen_string_literal: true

FactoryBot.define do
  factory :link do
    association :medium
    association :linked_medium, factory: :medium
  end
end
