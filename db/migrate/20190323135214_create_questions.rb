class CreateQuestions < ActiveRecord::Migration[5.2]
  def change
    create_table :questions do |t|
      t.text :text
      t.text :label
      t.text :hint
      t.integer :parent_id

      t.timestamps
    end
  end
end
