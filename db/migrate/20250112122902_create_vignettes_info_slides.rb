class CreateVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_info_slides do |t|
      t.references :vignettes_slide, null: false, foreign_key: true

      t.timestamps
    end
  end
end
