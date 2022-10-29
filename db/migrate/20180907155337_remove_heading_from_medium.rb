class RemoveHeadingFromMedium < ActiveRecord::Migration[5.2]
  def change
    remove_column :media, :heading, :string
  end
end
