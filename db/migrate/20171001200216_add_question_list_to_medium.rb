class AddQuestionListToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :question_list, :text
  end
end
