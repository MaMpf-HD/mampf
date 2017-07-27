class AddTypeToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :type, :string
  end
end
