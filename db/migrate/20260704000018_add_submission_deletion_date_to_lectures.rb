class AddSubmissionDeletionDateToLectures < ActiveRecord::Migration[8.0]
  def up
    add_column :lectures, :submission_deletion_date, :date

    # rubocop: disable Rails/SkipsModelValidations
    Assignment.group(:lecture_id).maximum(:deletion_date).each do |lecture_id, max_date|
      Lecture.find(lecture_id).update_column(:submission_deletion_date, max_date)
    end

    Lecture.where(submission_deletion_date: nil).find_each do |lecture|
      lecture.update_column(
        :submission_deletion_date,
        lecture.default_submission_deletion_date
      )
    end

    cap = Term.possible_deletion_dates.last
    if cap
      Lecture.where(Lecture.arel_table[:submission_deletion_date].gt(cap))
             .update_all(submission_deletion_date: cap)
    end
    # rubocop: enable Rails/SkipsModelValidations

    change_column_null :lectures, :submission_deletion_date, false
    add_index :lectures, :submission_deletion_date
  end

  def down
    remove_index :lectures, :submission_deletion_date, if_exists: true
    remove_column :lectures, :submission_deletion_date
  end
end
