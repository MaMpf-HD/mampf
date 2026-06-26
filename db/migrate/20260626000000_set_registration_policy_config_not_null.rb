class SetRegistrationPolicyConfigNotNull < ActiveRecord::Migration[8.0]
  class RegistrationPolicy < ApplicationRecord
  end

  def up
    # rubocop:disable Rails/SkipsModelValidations
    RegistrationPolicy.where(config: nil).update_all(config: {})
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null :registration_policies, :config, false
  end

  def down
    change_column_null :registration_policies, :config, true
  end
end
