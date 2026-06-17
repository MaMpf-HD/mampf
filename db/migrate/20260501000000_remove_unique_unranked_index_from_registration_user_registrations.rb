class RemoveUniqueUnrankedIndexFromRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    remove_index :registration_user_registrations, name: "index_reg_user_regs_unique_unranked"
  end
end
