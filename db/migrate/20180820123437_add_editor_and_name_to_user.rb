class AddEditorAndNameToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :editor, :boolean
    add_column :users, :name, :text
  end
end
