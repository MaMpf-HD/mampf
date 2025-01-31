class RemoveRedundantColumnsForV13 < ActiveRecord::Migration[6.0]
  def up
    remove_column :users, :edited_profile, :boolean
    remove_column :tutorials, :tutor_id, :integer
  end

  def down
    add_column :users, :edited_profile, :boolean
    add_column :tutorial, :tutor_id, :integer
  end
end
