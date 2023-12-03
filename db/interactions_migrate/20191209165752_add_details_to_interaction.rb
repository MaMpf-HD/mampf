class AddDetailsToInteraction < ActiveRecord::Migration[6.0]
  def change
    add_column :interactions, :controller_name, :text # rubocop:todo Rails/BulkChangeTable
    add_column :interactions, :action_name, :text
    add_column :interactions, :referrer_url, :text
  end
end
