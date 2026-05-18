class DropQuestionsRemarksQuizzesTables < ActiveRecord::Migration[5.2]
  def up
    remove_reference :answers, :question, index: true, foreign_key: true
    drop_table :questions
    drop_table :remarks
    drop_table :quizzes
    add_column :answers, :question_id, :integer
    add_index :answers, :question_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
