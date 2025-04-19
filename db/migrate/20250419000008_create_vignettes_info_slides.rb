class CreateVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_info_slides do |t|
      t.string :title, null: false
      t.references :vignettes_questionnaire, index: true, null: false
      t.string :icon_type

      t.timestamps
    end
  end
end
