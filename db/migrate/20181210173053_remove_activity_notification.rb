class RemoveActivityNotification < ActiveRecord::Migration[5.2]
  def change
    drop_table :notifications # rubocop:todo Rails/ReversibleMigration
    drop_table :subscriptions # rubocop:todo Rails/ReversibleMigration
  end
end
