class AddConfirmableToDeviseAgain < ActiveRecord::Migration[6.0]
  # NOTE: You can't use change, as User.update_all will fail in the down migration
  def up
    add_column :users, :confirmation_token, :string # rubocop:todo Rails/BulkChangeTable
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string # Only if using reconfirmable
    add_index :users, :confirmation_token, unique: true
    # To avoid a short time window between running the migration and updating all existing
    # users as confirmed, do the following
    User.update_all confirmed_at: DateTime.now # rubocop:todo Rails/SkipsModelValidations
    # All existing user accounts should be able to log in after this.
  end

  def down
    # rubocop:todo Rails/BulkChangeTable
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    # rubocop:enable Rails/BulkChangeTable
    remove_columns :users, :unconfirmed_email # Only if using reconfirmable
  end
end
