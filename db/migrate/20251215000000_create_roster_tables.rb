class CreateRosterTables < ActiveRecord::Migration[7.0]
  def change
    # Stores the official roster for tutorials
    create_table :tutorial_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tutorial, null: false, foreign_key: true
      # Tracks which campaign put the user here (for smart merges)
      t.references :source_campaign, foreign_key: { to_table: :registration_campaigns }

      t.timestamps
    end
    add_index :tutorial_memberships, [:user_id, :tutorial_id], unique: true

    # Stores the official roster for lectures (distinct from subscriptions/lecture_user_joins)
    create_table :lecture_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :lecture, null: false, foreign_key: true
      t.references :source_campaign, foreign_key: { to_table: :registration_campaigns }

      t.timestamps
    end
    add_index :lecture_memberships, [:user_id, :lecture_id], unique: true

    # Add tracking to the existing join table for talks
    add_reference :speaker_talk_joins, :source_campaign,
                  foreign_key: { to_table: :registration_campaigns }
  end
end
