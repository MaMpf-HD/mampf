class RenameKeksQuestionRemarkQuiz < ActiveRecord::Migration[5.2]
  def up
    # rubocop:todo Rails/SkipsModelValidations
    Medium.where(sort: "KeksQuestion").update_all(sort: "Question")
    # rubocop:enable Rails/SkipsModelValidations
    # rubocop:todo Rails/SkipsModelValidations
    Medium.where(sort: "KeksRemark").update_all(sort: "Remark")
    # rubocop:enable Rails/SkipsModelValidations
    # rubocop:todo Rails/SkipsModelValidations
    Medium.where(sort: "KeksQuiz").update_all(sort: "Quiz")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    # rubocop:todo Rails/SkipsModelValidations
    Medium.where(sort: "Question").update_all(sort: "KeksQuestion")
    # rubocop:enable Rails/SkipsModelValidations
    # rubocop:todo Rails/SkipsModelValidations
    Medium.where(sort: "Remark").update_all(sort: "KeksRemark")
    # rubocop:enable Rails/SkipsModelValidations
    # rubocop:todo Rails/SkipsModelValidations
    Medium.where(sort: "Quiz").update_all(sort: "KeksQuiz")
    # rubocop:enable Rails/SkipsModelValidations
  end
end
