class AddSelfMaterializationModeToRosterables < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorials, :self_materialization_mode, :integer, default: 0, null: false
    add_column :cohorts, :self_materialization_mode, :integer, default: 0, null: false
    add_column :talks, :self_materialization_mode, :integer, default: 0, null: false
    add_column :lectures, :self_materialization_mode, :integer, default: 0, null: false

    add_index :tutorials, :self_materialization_mode
    add_index :cohorts, :self_materialization_mode
    add_index :talks, :self_materialization_mode
    # No index for lectures: Lectures as rosterables need the column but the value
    # is always 0 (disabled), so indexing is not useful.
  end
end
