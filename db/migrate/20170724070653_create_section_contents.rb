class CreateSectionContents < ActiveRecord::Migration[5.1]
  def change
    create_table :section_contents do |t|
      t.references :section, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
