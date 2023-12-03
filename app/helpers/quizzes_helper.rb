# Quizzes Helper
module QuizzesHelper
  # rubocop:disable Rails/HelperInstanceVariable
  def answer_id(a_id, progress = @quiz_round.progress,
                vertex = @quiz_round.vertex)
    "r#{progress}q#{vertex[:id]}a#{a_id}"
  end

  def quiz_id(q_id = @quiz_round.quiz.id)
    "quiz#{q_id}"
  end

  def result_id(a_id, progress = @quiz_round.progress,
                vertex = @quiz_round.vertex)
    "result#{progress}q#{vertex[:id]}a#{a_id}"
  end

  def cross_id(a_id, progress = @quiz_round.progress,
               vertex = @quiz_round.vertex)
    "cross#{progress}q#{vertex[:id]}a#{a_id}"
  end
  # rubocop:enable Rails/HelperInstanceVariable

  def vertices_labels_no_end(quiz)
    special = [[I18n.t("admin.quiz.undefined"), 0]]
    list = quiz.vertices.keys.collect { |k| [vertex_label(quiz, k), k] }
    special.concat list
  end
end
