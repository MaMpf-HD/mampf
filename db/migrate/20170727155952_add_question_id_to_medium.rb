class AddQuestionIdToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :question_id, :integer
  end
end
