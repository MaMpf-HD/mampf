class AddImageDataToCourse < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :image_data, :text
  end
end
