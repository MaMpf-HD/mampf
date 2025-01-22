class ChangeTimeOnVignettesInfoSlidesTypeInSlideStatistics < ActiveRecord::Migration[7.1]
  def change
    rename_column :vignettes_slide_statistics, :time_on_info_slide, :time_on_info_slides
    # To store data in json format
    change_column :vignettes_slide_statistics, :time_on_info_slides, :text
  end
end
