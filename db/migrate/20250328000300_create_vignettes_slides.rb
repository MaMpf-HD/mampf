class CreateVignettesSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_slides do |t|
      t.string :title, null: false
      t.references :vignettes_questionnaire, null: false, foreign_key: true
      t.integer :position, null: false
      t.index :position

      t.timestamps
    end
  end
end
