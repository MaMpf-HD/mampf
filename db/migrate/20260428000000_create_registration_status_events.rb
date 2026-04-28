class CreateRegistrationStatusEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_status_events, id: :uuid,
                                              default: -> { "gen_random_uuid()" } do |t|
      t.uuid :registration_id, null: false
      t.uuid :registration_campaign_id, null: false
      t.string :action, null: false
      t.string :reason_type
      t.string :reason_code
      t.bigint :actor_id
      t.uuid :correlation_id
      t.integer :schema_version, null: false, default: 1
      t.jsonb :snapshot, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_column :registration_campaigns, :last_finalization_correlation_id, :uuid

    add_index :registration_campaigns, :last_finalization_correlation_id
    add_index :registration_status_events, :registration_id
    add_index :registration_status_events,
              [:registration_campaign_id, :action],
              name: "index_reg_status_events_on_campaign_and_action"
    add_index :registration_status_events,
              [:registration_campaign_id, :reason_type],
              name: "index_reg_status_events_on_campaign_and_reason_type"
    add_index :registration_status_events, :actor_id
    add_index :registration_status_events, :correlation_id

    add_foreign_key :registration_status_events,
                    :registration_user_registrations,
                    column: :registration_id
    add_foreign_key :registration_status_events, :registration_campaigns
    add_foreign_key :registration_status_events, :users, column: :actor_id
  end
end
