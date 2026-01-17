class AddSelfMaterializationModeToRosterables < ActiveRecord::Migration[7.1]
  def change
    add_column :tutorials, :self_materialization_mode, :integer, default: 0
    add_column :cohorts, :self_materialization_mode, :integer, default: 0
    add_column :talks, :self_materialization_mode, :integer, default: 0
    add_column :lectures, :self_materialization_mode, :integer, default: 0
  end
end
