class AddSubmissionMaxTeamSizeToLecture < ActiveRecord::Migration[6.0]
  def up
    add_column :lectures, :submission_max_team_size, :integer
  end

  def down
    remove_column :lectures, :submission_max_team_size, :integer
  end
end
