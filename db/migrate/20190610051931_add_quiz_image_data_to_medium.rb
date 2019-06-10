class AddQuizImageDataToMedium < ActiveRecord::Migration[6.0]
  def change
    add_column :media, :quiz_image_data, :text
  end
end
