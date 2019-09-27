class CreateImports < ActiveRecord::Migration[6.0]
  def change
    create_table :imports do |t|
      t.references :medium, null: false, foreign_key: true
      t.references :teachable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
