# A submission goes when its lecture's deletion date has passed or its only
# author deletes the account. The points it was marked with belong to the
# student's participation and stay, without the link to the deleted files.
class NullifyTaskPointSubmissionOnDelete < ActiveRecord::Migration[8.0]
  def up
    remove_foreign_key :assessment_task_points, :submissions
    add_foreign_key :assessment_task_points, :submissions, on_delete: :nullify
  end

  def down
    remove_foreign_key :assessment_task_points, :submissions
    add_foreign_key :assessment_task_points, :submissions
  end
end
