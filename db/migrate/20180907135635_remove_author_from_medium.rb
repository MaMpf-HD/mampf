class RemoveAuthorFromMedium < ActiveRecord::Migration[5.2]
  def change
    remove_column :media, :author, :string
  end
end
