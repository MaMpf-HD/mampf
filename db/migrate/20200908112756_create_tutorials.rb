class CreateTutorials < ActiveRecord::Migration[6.0]
  def up
    create_table :tutorials do |t|
      t.text :title
      t.references :tutor, null: false, foreign_key: false
      t.references :lecture, null: false, foreign_key: true

      t.timestamps
    end
  end

  def down
    drop_table :tutorials
  end
end
