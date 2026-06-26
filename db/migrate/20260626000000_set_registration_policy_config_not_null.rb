class SetRegistrationPolicyConfigNotNull < ActiveRecord::Migration[8.0]
  class RegistrationPolicy < ApplicationRecord
  end

  def up
    RegistrationPolicy.where(config: nil).find_each do |policy|
      # rubocop:disable Rails/SkipsModelValidations
      policy.update_columns(config: {})
      # rubocop:enable Rails/SkipsModelValidations
    end

    change_column_null :registration_policies, :config, false
  end

  def down
    change_column_null :registration_policies, :config, true
  end
end
