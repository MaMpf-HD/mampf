class CreateMediumTagJoins < ActiveRecord::Migration[5.1]
  def change
    create_table :medium_tag_joins do |t|
      t.references :medium, foreign_key: true
      t.references :tag, foreign_key: true

      t.timestamps
    end
  end
end
