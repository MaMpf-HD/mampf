# rubocop:disable Rails/
class AddEmailForSubmissionDecisionsToUser < ActiveRecord::Migration[6.0]
  def up
    add_column :users, :email_for_submission_decision, :boolean
  end

  def down
    remove_column :users, :email_for_submission_decision, :boolean
  end
end
# rubocop:enable Rails/
