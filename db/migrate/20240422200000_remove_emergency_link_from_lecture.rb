class RemoveEmergencyLinkFromLecture < ActiveRecord::Migration[7.0]
  def up
    remove_column :lectures, :emergency_link_status, :integer
    remove_column :lectures, :emergency_link, :text
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
