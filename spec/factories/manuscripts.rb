# frozen_string_literal: true

FactoryBot.define do
  factory :manuscript do
    transient do
      medium { build(:valid_medium) }
    end

    initialize_with { new(medium) }

    # TO DO: associate a medium with an actual attached manuscript, so that
    # a nontrivial manuscript results
  end
end
