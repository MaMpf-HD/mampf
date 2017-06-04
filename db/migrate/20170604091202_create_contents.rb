class CreateContents < ActiveRecord::Migration[5.1]
  def change
    create_table :contents do |t|
      t.references :course, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
