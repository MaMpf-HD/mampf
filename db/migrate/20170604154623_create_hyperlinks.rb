class CreateHyperlinks < ActiveRecord::Migration[5.1]
  def change
    create_table :hyperlinks do |t|
      t.string :link
      t.references :linkable, polymorphic: true

      t.timestamps
    end
  end
end
