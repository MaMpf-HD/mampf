FactoryBot.define do
  factory :question_sampler do
    transient do
      questions { Question.none }
      tags { Tag.none }
      # rubocop:disable Performance/CollectionLiteralInLoop
      count { [3, 4, 5].sample }
      # rubocop:enable Performance/CollectionLiteralInLoop
    end

    initialize_with { new(questions, tags, count) }
  end
end
