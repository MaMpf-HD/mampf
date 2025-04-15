class CreateVignettesCompletionMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_completion_messages do |t|
      t.references :lecture, null: false, foreign_key: true
      t.timestamps
    end
  end
end
