class CreateAdditionalContents < ActiveRecord::Migration[5.1]
  def change
    create_table :additional_contents do |t|
      t.references :lecture, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
