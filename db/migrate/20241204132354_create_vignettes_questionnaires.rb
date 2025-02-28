class CreateVignettesQuestionnaires < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_questionnaires do |t|
      t.string :title
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
