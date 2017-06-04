class CreateDisabledContents < ActiveRecord::Migration[5.1]
  def change
    create_table :disabled_contents do |t|
      t.references :lecture, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
