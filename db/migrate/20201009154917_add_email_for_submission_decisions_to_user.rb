class AddEmailForSubmissionDecisionsToUser < ActiveRecord::Migration[6.0]
  def up
    # rubocop:todo Rails/ThreeStateBooleanColumn
    add_column :users, :email_for_submission_decision, :boolean
    # rubocop:enable Rails/ThreeStateBooleanColumn
  end

  def down
    remove_column :users, :email_for_submission_decision, :boolean
  end
end
