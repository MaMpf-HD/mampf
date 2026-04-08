class AddConfirmedRegistrationsCountToRegistrationItems < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_items, :confirmed_registrations_count, :integer, default: 0,
                                                                              null: false
  end
end
