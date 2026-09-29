class AddPersonalDataToUsers < ActiveRecord::Migration[8.0]
  def change
    change_table :users, bulk: true do |t|
      t.string :first_name
      t.string :last_name
      t.string :matriculation_number
      t.string :uni_id
      t.datetime :personal_data_confirmed_at
      t.datetime :personal_data_declined_at
    end
    add_index :users, :matriculation_number, unique: true,
                                             where: "matriculation_number IS NOT NULL"
    add_index :users, :uni_id, unique: true, where: "uni_id IS NOT NULL"
  end
end
