# When the students were told about their results: the mail goes out on the
# first publication only, and the lecture home shows a new result up top
# until the student closes it.
class AddResultNoticeColumns < ActiveRecord::Migration[8.0]
  def change
    add_column :assessment_assessments, :results_notified_at, :datetime
    add_column :assessment_participations, :result_seen_at, :datetime
  end
end
