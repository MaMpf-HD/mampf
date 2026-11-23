class AddAddedByToUserSubmissionJoins < ActiveRecord::Migration[8.0]
  def change
    add_reference :user_submission_joins, :added_by,
                  foreign_key: { to_table: :users, on_delete: :nullify }
  end
end
