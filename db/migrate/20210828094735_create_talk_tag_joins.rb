class CreateTalkTagJoins < ActiveRecord::Migration[6.1]
  def up
    create_table :talk_tag_joins do |t|
      t.references :talk, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end

  def down
    drop_table :talk_tag_joins
  end
end
