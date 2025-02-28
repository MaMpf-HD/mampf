class CreateVignettesOptions < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_options do |t|
      t.string :text
      t.references :vignettes_question, null: false, foreign_key: true

      t.timestamps
    end
  end
end
