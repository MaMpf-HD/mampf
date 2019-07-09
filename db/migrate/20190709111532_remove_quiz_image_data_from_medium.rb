class RemoveQuizImageDataFromMedium < ActiveRecord::Migration[6.0]
  def change
    remove_column :media, :quiz_image_data, :text
  end
end
