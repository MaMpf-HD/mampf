class RemoveEditorFromUser < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :editor, :boolean
  end
end
