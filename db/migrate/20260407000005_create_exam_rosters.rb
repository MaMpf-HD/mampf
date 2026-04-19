class CreateExamRosters < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_rosters, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.bigint :exam_id, null: false
      t.bigint :user_id, null: false
      t.uuid :source_campaign_id

      t.timestamps
    end

    add_index :exam_rosters, :exam_id
    add_index :exam_rosters, :user_id
    add_index :exam_rosters, [:user_id, :exam_id], unique: true
    add_index :exam_rosters, :source_campaign_id

    add_foreign_key :exam_rosters, :exams
    add_foreign_key :exam_rosters, :users
    add_foreign_key :exam_rosters, :registration_campaigns, column: :source_campaign_id
  end
end
