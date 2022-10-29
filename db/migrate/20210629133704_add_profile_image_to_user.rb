class AddProfileImageToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :image_data, :text
  end
end
