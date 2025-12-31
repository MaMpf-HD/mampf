class AddManualRosterModeToRosterables < ActiveRecord::Migration[8.0]
  def change
    add_column :tutorials, :manual_roster_mode, :boolean, default: false, null: false
    add_column :talks, :manual_roster_mode, :boolean, default: false, null: false
    add_column :lectures, :manual_roster_mode, :boolean, default: false, null: false
  end
end
