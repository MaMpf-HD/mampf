class CreateExamRosterEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_roster_entries,
                 id: :uuid,
                 default: -> { "gen_random_uuid()" } do |t|
      t.bigint :exam_id, null: false
      t.bigint :user_id, null: false
      t.uuid :source_campaign_id
      t.datetime :excluded_at

      t.timestamps
    end

    add_index :exam_roster_entries, :exam_id
    add_index :exam_roster_entries, :user_id
    add_index :exam_roster_entries, [:user_id, :exam_id], unique: true
    add_index :exam_roster_entries, :source_campaign_id
    add_index :exam_roster_entries, [:exam_id, :excluded_at]

    add_foreign_key :exam_roster_entries, :exams
    add_foreign_key :exam_roster_entries, :users
    add_foreign_key :exam_roster_entries, :registration_campaigns,
                    column: :source_campaign_id
  end
end
