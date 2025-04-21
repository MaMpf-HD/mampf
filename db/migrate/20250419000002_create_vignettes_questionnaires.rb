class CreateVignettesQuestionnaires < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_questionnaires do |t|
      t.string :title
      t.references :lecture, null: false, foreign_key: true
      t.boolean :published
      t.boolean :editable, default: true

      t.timestamps
    end
  end
end
