class AddDefaultAnnotationsStatusToLectureAndMedia < ActiveRecord::Migration[7.0]
  def change
    Lecture.update_all(annotations_status: -1) # rubocop:todo Rails/SkipsModelValidations
    Medium.update_all(annotations_status: 0) # rubocop:todo Rails/SkipsModelValidations
  end
end
