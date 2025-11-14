class CreateRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_user_registrations do |t|
      t.references :campaign,
                   null: false,
                   foreign_key: { to_table: :registration_campaigns },
                   index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :item,
                   null: true,
                   foreign_key: { to_table: :registration_items },
                   index: true
      t.integer :preference_rank
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :registration_user_registrations,
              [:campaign_id, :user_id],
              unique: true,
              name: "index_registration_user_registrations_uniqueness"
    add_index :registration_user_registrations, :status
  end
end
