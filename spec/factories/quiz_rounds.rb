# frozen_string_literal: true

FactoryBot.define do
  factory :quiz_round do
    transient do
      quiz { FactoryBot.create(:valid_quiz, :with_quiz_graph) }
      progress { (1..quiz.questions_count).to_a.sample }
      counter { progress }
      question { Question.find(quiz.vertices[progress][:id]) }
      answer_shuffle { question.answers.pluck(:id) }
      crosses { answer_shuffle.select { rand(2).zero? } }
      session_id { Faker::Crypto.md5 }
    end

    initialize_with do
      new({ id: quiz.id,
            quiz: { crosses: crosses,
                    progress: progress,
                    counter: counter,
                    answer_shuffle: answer_shuffle.to_s,
                    session_id: session_id } })
    end
  end

  # TO DO
  # write a trait that handles quiz rounds for non-MC questions
  # for that we need a factory for quizzes/questions that incorporates
  # non-MC questions
end
