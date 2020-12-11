class RemoveIntegerIdFromSubmission < ActiveRecord::Migration[6.0]
  def up
    remove_column :submissions, :integer_id, :integer
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
