FactoryBot.define do
  factory :solution do
    transient do
      sort do
        # rubocop:disable Performance/CollectionLiteralInLoop
        [:mampf_expression, :mampf_matrix, :mampf_tuple, :mampf_set].sample
        # rubocop:enable Performance/CollectionLiteralInLoop
      end
      content { build(sort) }
    end

    initialize_with { new(content) }
  end
end
