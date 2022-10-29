class DropCourseUserJoinTable < ActiveRecord::Migration[6.0]
  def up
    drop_table :course_user_joins
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
