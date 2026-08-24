class RequireConsentOnUsers < ActiveRecord::Migration[8.0]
  class User < ApplicationRecord
  end

  def up
    # rubocop:disable Rails/SkipsModelValidations
    User.where(consents: nil).update_all(consents: false)
    User.where(consents: false).update_all(consented_at: nil)
    # rubocop:enable Rails/SkipsModelValidations

    change_column_default :users, :consents, from: nil, to: false
    change_column_null :users, :consents, false
  end

  def down
    change_column_null :users, :consents, true
    change_column_default :users, :consents, from: false, to: nil
  end
end
