class CreateVignettesSlideStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_slide_statistics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :vignettes_answer, foreign_key: { to_table: :vignettes_answers }
      t.integer :time_on_slide
      t.text :time_on_info_slides
      t.text :info_slides_access_count
      t.text :info_slides_first_access_time

      t.timestamps
    end
  end
end
