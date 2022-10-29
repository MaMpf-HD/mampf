class CreateSpeakerTalkJoins < ActiveRecord::Migration[6.1]
  def up
    create_table :speaker_talk_joins do |t|
      t.references :talk, null: false, foreign_key: true
      t.references :speaker, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end

  def down
    drop_table :speaker_talk_joins
  end
end
