class CreateVignettesUserAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_user_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :vignettes_questionnaire, null: false, foreign_key: true

      t.timestamps
    end
  end
end
