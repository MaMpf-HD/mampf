class AddDefaultAnnotationsStatusToLectureAndMedia < ActiveRecord::Migration[7.0]
  def change
    Lecture.update_all(annotations_status: -1)
    Medium.update_all(annotations_status: 0)
  end
end
