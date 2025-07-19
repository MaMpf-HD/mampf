class DropClickersAndClickerVotes < ActiveRecord::Migration[8.0]
  def up
    # Drop clicker_votes first since it has a foreign key reference to clickers
    drop_table :clicker_votes
    drop_table :clickers
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
