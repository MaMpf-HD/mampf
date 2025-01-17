class AddPositionToSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_slides, :position, :integer
    add_index :vignettes_slides, :position
  end
end
