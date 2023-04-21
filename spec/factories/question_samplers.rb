# frozen_string_literal: true

FactoryBot.define do
  factory :question_sampler do
    transient do
      questions { Question.none }
      tags { Tag.none }
      count { [3, 4, 5].sample }
    end

    initialize_with { new(questions, tags, count) }
  end
end
