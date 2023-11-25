class RemoveDetailsFromInteractions < ActiveRecord::Migration[6.0]
  def change
    remove_column :interactions, :controller_name, :text # rubocop:todo Rails/BulkChangeTable
    remove_column :interactions, :action_name, :text
  end
end
