class AddExclusiveAssignmentToRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    add_column :registration_user_registrations,
               :exclusive_assignment,
               :boolean,
               null: false,
               default: false

    add_index :registration_user_registrations,
              [:registration_campaign_id, :user_id],
              unique: true,
              where: "exclusive_assignment = true AND preference_rank IS NULL",
              name: "index_reg_user_regs_unique_exclusive_assignment_unranked"

    add_index :registration_user_registrations,
              [:registration_campaign_id, :user_id, :registration_item_id],
              unique: true,
              name: "index_reg_user_regs_unique_item_user"
  end
end
