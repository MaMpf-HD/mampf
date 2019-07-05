class Answer < ApplicationRecord
  belongs_to :question, touch: true
  before_destroy :question_not_orphaned?
  after_destroy :update_quizzes
  after_create :update_quizzes
  after_save :touch_medium

  def conditional_explanation(correct)
    unless /\(korrekt:.*\):\(inkorrekt:.*\)/.match?(explanation)
      return explanation
    end
    unless correct
      return explanation.string_between_markers(':(inkorrekt:', ')')
    end
    explanation.string_between_markers('(korrekt:', '):')
  end

  def duplicate(new_question)
    Answer.create(text: text, value: value, explanation: explanation,
                  question: new_question)
  end

  def text_join
    "#{text} #{explanation}"
  end

  private

  def question_not_orphaned?
    throw(:abort) if question.answers.size == 1
    true
  end

  def update_quizzes
    question.quiz_ids.each do |q|
      quiz = Quiz.find(q)
      quiz_graph = quiz.quiz_graph
      vertices = quiz_graph.find_vertices(question)
      vertices.each do |v|
        quiz_graph.reset_vertex_answers_change(v)
      end
      quiz.update(quiz_graph: quiz_graph)
    end
  end

  def touch_medium
    question.becomes(Medium).update(updated_at: Time.now)
  end
end
