class AddSubmissionEmailFlagsToUser < ActiveRecord::Migration[6.0]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_submission_upload, :boolean # rubocop:todo Rails/BulkChangeTable
    # rubocop:enable Rails/ThreeStateBooleanColumn
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_submission_removal, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_submission_join, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_submission_leave, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end

  def down
    # rubocop:todo Rails/BulkChangeTable
    remove_column :users, :email_for_submission_upload, :boolean
    # rubocop:enable Rails/BulkChangeTable
    remove_column :users, :email_for_submission_removal, :boolean
    remove_column :users, :email_for_submission_join, :boolean
    remove_column :users, :email_for_submission_leave, :boolean
  end
end
