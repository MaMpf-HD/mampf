class DropConnectionTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :connections
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
