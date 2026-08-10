class AddRejectionOverriddenAtToRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_user_registrations,
               :rejection_overridden_at,
               :datetime

    add_index :registration_user_registrations,
              :rejection_overridden_at,
              name: "index_reg_user_regs_on_rejection_overridden_at"
  end
end
