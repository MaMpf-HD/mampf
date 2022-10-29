# frozen_string_literal: true

FactoryBot.define do
  factory :medium_tag_join do
    association :medium
    association :tag
  end
end
