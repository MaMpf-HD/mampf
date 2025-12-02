class CreateRegistrationPolicies < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_policies do |t|
      t.references :registration_campaign,
                   null: false,
                   foreign_key: true,
                   index: true
      t.integer :kind, null: false
      # no presence validation on position, as acts_as_list manages it
      t.integer :phase, null: false, default: 0
      t.integer :position
      t.boolean :active, null: false, default: true
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :registration_policies,
              [:registration_campaign_id, :position],
              unique: true,
              name: "index_registration_policies_uniqueness"
    add_index :registration_policies, :kind
    add_index :registration_policies, :phase
    add_index :registration_policies, :active
  end
end
