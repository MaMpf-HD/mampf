class RemoveLessonCourseLectureIdsFromLearningAsset < ActiveRecord::Migration[5.1]
  def change
    remove_column :learning_assets, :course_id, :index
    remove_column :learning_assets, :lecture_id, :index
    remove_column :learning_assets, :lesson_id, :index
  end
end
