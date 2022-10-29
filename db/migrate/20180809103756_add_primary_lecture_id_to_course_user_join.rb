class AddPrimaryLectureIdToCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    add_column :course_user_joins, :primary_lecture_id, :integer
  end
end
