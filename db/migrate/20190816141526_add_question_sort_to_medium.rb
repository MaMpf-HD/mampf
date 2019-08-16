class AddQuestionSortToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :question_sort, :text
  end
end
