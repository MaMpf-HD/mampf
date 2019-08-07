class CreateClickers < ActiveRecord::Migration[6.0]
  def change
    create_table :clickers do |t|
      t.integer :editor_id
      t.references :teachable, polymorphic: true, null: false
      t.integer :question_id
      t.text :code

      t.timestamps
    end
    add_index :clickers, :editor_id
  end
end
