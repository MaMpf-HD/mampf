class CreateRemarks < ActiveRecord::Migration[5.2]
  def change
    create_table :remarks do |t|
      t.text :text
      t.text :label
      t.integer :parent_id

      t.timestamps
    end
  end
end
