class CreateVignettesAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_answers do |t|
      t.string :type
      t.references :vignettes_question, null: false, foreign_key: true
      t.references :vignettes_slide, null: false, foreign_key: true

      t.timestamps
    end
  end
end
