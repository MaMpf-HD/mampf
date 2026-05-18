class CreateVignettesAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_user_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :vignettes_questionnaire, null: false, foreign_key: true
      t.timestamps
    end

    create_table :vignettes_answers do |t|
      t.string :type
      t.references :vignettes_question, null: false, foreign_key: true
      t.references :vignettes_slide, null: false, foreign_key: true
      t.references :vignettes_user_answer, null: false, foreign_key: true
      t.text :text
      t.string :likert_scale_value
      t.timestamps
    end
  end
end
