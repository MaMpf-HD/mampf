class AddInfoSlideAccessCountToVignettesSlideStatistics < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_slide_statistics, :info_slides_access_count, :text
  end
end
