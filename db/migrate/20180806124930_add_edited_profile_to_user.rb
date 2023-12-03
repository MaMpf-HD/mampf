class AddEditedProfileToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :edited_profile, :boolean
  end
end
