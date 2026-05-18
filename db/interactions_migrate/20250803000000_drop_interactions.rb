class DropInteractions < ActiveRecord::Migration[8.0]
  def up
    drop_table :interactions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
