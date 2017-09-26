class AddHeadingToMedium < ActiveRecord::Migration[5.1]
  def change
    add_column :media, :heading, :string
  end
end
