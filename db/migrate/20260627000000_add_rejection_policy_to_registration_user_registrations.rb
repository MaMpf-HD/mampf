class AddRejectionPolicyToRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_reference :registration_user_registrations,
                  :rejection_policy,
                  type: :uuid,
                  foreign_key: { to_table: :registration_policies },
                  index: true
  end
end
