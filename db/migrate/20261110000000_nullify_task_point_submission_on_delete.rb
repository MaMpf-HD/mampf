# Task points outlive their submission. It is deleted with the lecture's
# deletion date or its author's account; the points belong to the
# participation.
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
