class DropQuestionsRemarksQuizzesTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :questions
    drop_table :remarks
    drop_table :quizzes
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
