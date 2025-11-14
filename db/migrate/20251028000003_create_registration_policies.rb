class CreateRegistrationPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_policies do |t|
      t.references :campaign,
                   null: false,
                   foreign_key: { to_table: :registration_campaigns },
                   index: true
      t.integer :kind, null: false
      t.integer :phase, null: false, default: 0
      t.integer :position, null: false
      t.boolean :active, null: false, default: true
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :registration_policies,
              [:campaign_id, :position],
              unique: true,
              name: "index_registration_policies_uniqueness"
    add_index :registration_policies, :kind
    add_index :registration_policies, :phase
    add_index :registration_policies, :active
  end
end
