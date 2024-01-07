# rubocop:disable Rails/
class AddSubmissionEmailFlagsToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :email_for_submission_upload, :boolean
    add_column :users, :email_for_submission_removal, :boolean
    add_column :users, :email_for_submission_join, :boolean
    add_column :users, :email_for_submission_leave, :boolean
  end

  def down
    remove_column :users, :email_for_submission_upload, :boolean
    remove_column :users, :email_for_submission_removal, :boolean
    remove_column :users, :email_for_submission_join, :boolean
    remove_column :users, :email_for_submission_leave, :boolean
  end
end
# rubocop:enable Rails/
