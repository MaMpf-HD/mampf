class RemoveLessonCourseLectureFromLearningAsset < ActiveRecord::Migration[5.1]
  def change
    remove_column :media, :course_id
    remove_column :media, :lecture_id
    remove_column :media, :lesson_id
  end
end
