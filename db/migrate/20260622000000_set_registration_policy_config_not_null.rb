class SetRegistrationPolicyConfigNotNull < ActiveRecord::Migration[8.0]
  class RegistrationPolicy < ApplicationRecord
    self.table_name = "registration_policies"
  end

  def up
    RegistrationPolicy.where(config: nil).find_each do |policy|
      policy.update_columns(config: {})
    end

    change_column_null :registration_policies, :config, false
  end

  def down
    change_column_null :registration_policies, :config, true
  end
end
