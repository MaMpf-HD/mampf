# Quizzes Helper
module QuizzesHelper
  def answer_id(a_id, progress = @quiz_round.progress,
                vertex = @quiz_round.vertex)
    "r" + progress.to_s + "q" + vertex[:id].to_s + "a" + a_id.to_s
  end

  def quiz_id(q_id = @quiz_round.quiz.id)
    "quiz" + q_id.to_s
  end

  def result_id(a_id, progress = @quiz_round.progress,
                vertex = @quiz_round.vertex)
    "result" + progress.to_s + "q" + vertex[:id].to_s + "a" + a_id.to_s
  end

  def cross_id(a_id, progress = @quiz_round.progress,
               vertex = @quiz_round.vertex)
    "cross" + progress.to_s + "q" + vertex[:id].to_s + "a" + a_id.to_s
  end

  def vertices_labels_no_end(quiz)
    special = [[I18n.t("admin.quiz.undefined"), 0]]
    list = quiz.vertices.keys.collect { |k| [vertex_label(quiz, k), k] }
    special.concat list
  end
end
