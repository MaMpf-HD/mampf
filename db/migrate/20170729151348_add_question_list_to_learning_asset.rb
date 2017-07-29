class AddQuestionListToLearningAsset < ActiveRecord::Migration[5.1]
  def change
    add_column :learning_assets, :question_list, :string
  end
end
