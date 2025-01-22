class RemoveVignettesSlideIdFromVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    remove_column :vignettes_info_slides, :vignettes_slide_id, :bigint
  end
end
