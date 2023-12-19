class AddInvitedUserIdsToSubmission < ActiveRecord::Migration[6.0]
  def up
    add_column :submissions, :invited_user_ids, :integer, array: true,
                                                          default: []
  end

  def down
    remove_column :submissions, :invited_user_ids
  end
end
