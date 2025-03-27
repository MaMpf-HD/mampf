class AddTotalSlideTimeToVignettesSlideStatistics < ActiveRecord::Migration[7.1]
  def change
    add_column :vignettes_slide_statistics, :total_time_on_slide, :integer
  end
end
