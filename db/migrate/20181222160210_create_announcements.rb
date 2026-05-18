class CreateAnnouncements < ActiveRecord::Migration[5.2]
  def change
    create_table :announcements do |t|
      t.references :lecture, foreign_key: true
      t.references :announcer, foreign_key: { to_table: :users }
      t.text :details

      t.timestamps
    end
  end
end
