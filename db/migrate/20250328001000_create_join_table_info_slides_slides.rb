class CreateJoinTableInfoSlidesSlides < ActiveRecord::Migration[7.1]
  def change
    create_join_table :vignettes_info_slides, :vignettes_slides do |t|
      t.index [:vignettes_info_slide_id, :vignettes_slide_id]
      t.index [:vignettes_slide_id, :vignettes_info_slide_id]
    end
  end
end
