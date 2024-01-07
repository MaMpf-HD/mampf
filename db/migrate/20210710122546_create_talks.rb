class CreateTalks < ActiveRecord::Migration[6.1]
  def up
    create_table :talks do |t|
      t.references :lecture, null: false, foreign_key: true

      t.timestamps
    end
  end

  def down
    drop_table :talks
  end
end
