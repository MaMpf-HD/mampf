class CreateVignettesQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_questions do |t|
      t.string :type
      t.text :question_text
      t.references :vignettes_slide, null: false, foreign_key: true

      t.timestamps
    end
  end
end
