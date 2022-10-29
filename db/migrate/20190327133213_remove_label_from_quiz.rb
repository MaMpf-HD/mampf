class RemoveLabelFromQuiz < ActiveRecord::Migration[5.2]
  def change
    remove_column :quizzes, :label, :text
  end
end
