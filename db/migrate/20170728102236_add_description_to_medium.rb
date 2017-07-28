class AddDescriptionToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :description, :string
  end
end
