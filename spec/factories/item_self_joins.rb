# frozen_string_literal: true

FactoryBot.define do
  factory :item_self_join do
    association :item
    association :related_item, factory: :item
  end
end
