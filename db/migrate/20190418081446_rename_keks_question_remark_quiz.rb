# rubocop:disable Rails/
class RenameKeksQuestionRemarkQuiz < ActiveRecord::Migration[5.2]
  def up
    Medium.where(sort: "KeksQuestion").update_all(sort: "Question")
    Medium.where(sort: "KeksRemark").update_all(sort: "Remark")
    Medium.where(sort: "KeksQuiz").update_all(sort: "Quiz")
  end

  def down
    Medium.where(sort: "Question").update_all(sort: "KeksQuestion")
    Medium.where(sort: "Remark").update_all(sort: "KeksRemark")
    Medium.where(sort: "Quiz").update_all(sort: "KeksQuiz")
  end
end
# rubocop:enable Rails/
