class AddLastModifiedByUsersAtToSubmission < ActiveRecord::Migration[6.0]
  def up
    add_column :submissions, :last_modification_by_users_at, :datetime
  end

  def down
    remove_column :submissions, :last_modification_by_users_at, :datetime
  end
end
