# frozen_string_literal: true

FactoryBot.define do
  factory :solution do
    transient do
      sort { [:mampf_expression, :mampf_matrix, :mampf_tuple,
              :mampf_set].sample }
      content { build(sort) }
    end

    initialize_with { new(content) }
  end
end
