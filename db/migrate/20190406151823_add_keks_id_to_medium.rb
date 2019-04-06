class AddKeksIdToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :keks_id, :integer
  end
end
