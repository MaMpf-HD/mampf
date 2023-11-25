class RemoveConfirmablefromDevise < ActiveRecord::Migration[5.1]
  def change
    # rubocop:todo Rails/ReversibleMigration
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
    # rubocop:enable Rails/ReversibleMigration
  end
end
