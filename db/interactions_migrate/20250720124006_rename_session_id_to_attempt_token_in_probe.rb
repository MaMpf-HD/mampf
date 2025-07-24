class RenameSessionIdToAttemptTokenInProbe < ActiveRecord::Migration[8.0]
  def up
    rename_column :probes, :session_id, :attempt_token
  end

  def down
    rename_column :probes, :attempt_token, :session_id
  end
end
