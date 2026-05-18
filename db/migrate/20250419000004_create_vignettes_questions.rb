class CreateVignettesQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_questions do |t|
      t.string :type
      t.text :question_text, limit: 10_000
      t.references :vignettes_slide, null: false, foreign_key: true
      t.boolean :only_integer, default: false
      t.decimal :min_number, precision: 10
      t.decimal :max_number, precision: 10
      t.string :language, default: "en"

      t.timestamps
    end
  end
end
