# frozen_string_literal: true

FactoryBot.define do
  factory :solution do
    transient do
      sort do
        [:mampf_expression, :mampf_matrix, :mampf_tuple, :mampf_set].sample
      end
      content { build(sort) }
    end

    initialize_with { new(content) }
  end
end
