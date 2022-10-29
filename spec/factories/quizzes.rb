# frozen_string_literal: true

FactoryBot.define do
  factory :quiz, parent: :medium, class: 'Quiz' do
    sort { 'Quiz' }

    transient do
      teachable_sort { :course }
      questions_count { 3 }
    end

    trait :with_quiz_graph do
      after :build do |q, evaluator|
        q.quiz_graph = build(:quiz_graph, :linear,
                             questions_count: evaluator.questions_count)
      end
    end

    factory :valid_quiz, traits: [:with_description, :with_editors,
                                  :with_teachable]

    factory :valid_random_quiz, traits: [:with_description] do
      sort { 'RandomQuiz' }
    end
  end
end
