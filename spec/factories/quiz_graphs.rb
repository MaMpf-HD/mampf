# frozen_string_literal: true

FactoryBot.define do
  factory :quiz_graph do
    trait :linear do
      transient do
        questions_count { 3 }
      end

      after(:build) do |q, evaluator|
        questions = create_list(:valid_question, evaluator.questions_count,
                                :with_answers)
        question_list = questions.map.with_index do |question, i|
          [i + 1, { type: 'Question', id: question.id }]
        end
        q.vertices = Hash[question_list]
        q.edges = {}
        q.root = 1
        q.default_table = {}
        (1..evaluator.questions_count).each do |i|
          q.default_table[i] = i < evaluator.questions_count ? i + 1 : -1
        end
      end
    end
  end
end
