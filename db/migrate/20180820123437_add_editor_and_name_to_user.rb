class AddEditorAndNameToUser < ActiveRecord::Migration[5.2]
  def change
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :editor, :boolean # rubocop:todo Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
    # rubocop:enable Rails/ThreeStateBooleanColumn
    add_column :users, :name, :text
  end
end
