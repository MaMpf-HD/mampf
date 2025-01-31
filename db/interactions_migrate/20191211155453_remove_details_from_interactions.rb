class RemoveDetailsFromInteractions < ActiveRecord::Migration[6.0]
  def change
    remove_column :interactions, :controller_name, :text
    remove_column :interactions, :action_name, :text
  end
end
