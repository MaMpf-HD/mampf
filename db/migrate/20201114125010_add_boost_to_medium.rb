class AddBoostToMedium < ActiveRecord::Migration[6.0]
  def up
    add_column :media, :boost, :float, default: 0
  end

  def down
		remove_column :media, :boost, :float
  end
end
