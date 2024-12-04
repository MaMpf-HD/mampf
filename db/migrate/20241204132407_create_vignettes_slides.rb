class CreateVignettesSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_slides do |t|
      t.references :vignettes_questionnaire, null: false, foreign_key: true

      t.timestamps
    end
  end
end
