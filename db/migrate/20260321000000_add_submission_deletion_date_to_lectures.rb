class AddSubmissionDeletionDateToLectures < ActiveRecord::Migration[8.0]
  def up
    add_column :lectures, :submission_deletion_date, :date

    # rubocop: disable Rails/SkipsModelValidations
    Assignment.group(:lecture_id).maximum(:deletion_date).each do |lecture_id, max_date|
      Lecture.find(lecture_id).update_column(:submission_deletion_date, max_date)
    end
    # rubocop: enable Rails/SkipsModelValidations
  end

  def down
    remove_column :lectures, :submission_deletion_date
  end
end
