class ChangeSlideStatisticsAssociations < ActiveRecord::Migration[7.0]
  def change
    remove_reference :vignettes_slide_statistics, :vignettes_slide, foreign_key: true
    add_reference :vignettes_slide_statistics, :vignettes_answer,
                  foreign_key: { to_table: :vignettes_answers }
  end
end
