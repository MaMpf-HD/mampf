class CreateVignettesSlideStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_slide_statistics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :vignettes_slide, null: false, foreign_key: true
      t.integer :time_on_slide
      t.integer :time_on_info_slide

      t.timestamps
    end
  end
end
