class AddUniqueIndexToRegistrationItems < ActiveRecord::Migration[8.0]
  def change
    add_index :registration_items, [:registerable_type, :registerable_id],
              unique: true,
              name: "index_registration_items_on_unique_registerable"
  end
end
