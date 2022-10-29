class DropTeacherTable < ActiveRecord::Migration[5.2]
  def up
    drop_table :teachers
  end

  def down
    create_table :teachers do |t|
      t.string :name
      t.string :email
      t.text :homepage

      t.timestamps
    end
  end
end
