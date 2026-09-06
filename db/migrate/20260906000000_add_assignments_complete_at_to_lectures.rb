class AddAssignmentsCompleteAtToLectures < ActiveRecord::Migration[8.0]
  # Whether every assignment of the term is on record. Nullable on purpose:
  # nobody has said so for any lecture that exists today, and "not said" is a
  # different thing from "said no".
  def change
    add_column :lectures, :assignments_complete_at, :datetime
  end
end
