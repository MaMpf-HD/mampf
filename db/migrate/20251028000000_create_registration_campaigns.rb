class CreateRegistrationCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_campaigns do |t|
      t.string :campaignable_type, null: false
      t.bigint :campaignable_id, null: false
      t.string :title, null: false
      t.integer :allocation_mode, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.boolean :planning_only, null: false, default: false
      t.datetime :registration_deadline

      t.timestamps
    end

    add_index :registration_campaigns,
              [:campaignable_type, :campaignable_id],
              name: "index_registration_campaigns_on_campaignable"
    add_index :registration_campaigns, :status
    add_index :registration_campaigns, :allocation_mode
  end
end
