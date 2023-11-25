class AddQuarantineToItem < ActiveRecord::Migration[5.2]
  def change
    add_column :items, :quarantine, :boolean # rubocop:todo Rails/ThreeStateBooleanColumn
  end
end
