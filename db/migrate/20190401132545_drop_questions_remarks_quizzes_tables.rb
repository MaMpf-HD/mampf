class DropQuestionsRemarksQuizzesTables < ActiveRecord::Migration[5.2]
  def up
    remove_reference :answers, :question, index: true, foreign_key: true
    drop_table :questions
    drop_table :remarks
    drop_table :quizzes
    add_reference :answers, :question, foreign_key: true
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
