class AddSubmissionDeletionColumnsToTerm < ActiveRecord::Migration[6.0]
  def up
    add_column :terms, :submission_deletion_mail, :datetime
    add_column :terms, :submission_deletion_reminder, :datetime
    add_column :terms, :submissions_deleted_at, :datetime
  end

  def down
    remove_column :terms, :submission_deletion_mail, :datetime
    remove_column :terms, :submission_deletion_reminder, :datetime
    remove_column :terms, :submissions_deleted_at, :datetime
  end
end
