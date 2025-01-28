class CreateVignettesInfoSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_info_slides do |t|
      t.string :title
      t.references :vignettes_questionnaire, index: true
      t.string :icon

      t.timestamps
    end
  end
end
