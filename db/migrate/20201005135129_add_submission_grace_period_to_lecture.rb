class AddSubmissionGracePeriodToLecture < ActiveRecord::Migration[6.0]
  def change
    add_column :lectures, :submission_grace_period, :integer, default: 15
  end
end
