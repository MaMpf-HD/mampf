class CreateRegistrationItems < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_items do |t|
      t.references :campaign,
                   null: false,
                   foreign_key: { to_table: :registration_campaigns },
                   index: true
      t.string :registerable_type, null: false
      t.bigint :registerable_id, null: false

      t.timestamps
    end

    add_index :registration_items,
              [:registerable_type, :registerable_id],
              name: "index_registration_items_on_registerable"
    add_index :registration_items,
              [:campaign_id, :registerable_type, :registerable_id],
              unique: true,
              name: "index_registration_items_uniqueness"
  end
end
