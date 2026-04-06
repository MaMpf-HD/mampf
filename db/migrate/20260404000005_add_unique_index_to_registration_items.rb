class AddUniqueIndexToRegistrationItems < ActiveRecord::Migration[8.0]
  def change
    remove_index :registration_items,
                 [:registerable_type, :registerable_id],
                 name: "index_registration_items_on_registerable"
    remove_index :registration_items,
                 [:registration_campaign_id, :registerable_type, :registerable_id],
                 unique: true,
                 name: "index_registration_items_uniqueness"

    add_index :registration_items, [:registerable_type, :registerable_id],
              unique: true,
              name: "index_registration_items_on_unique_registerable"
  end
end
