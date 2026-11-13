# Clears the deletion dates the user cleaner had set before it was paused.
# They have long passed, so its first run would delete those accounts without
# another warning, although some of their owners could not sign in during the
# pause. Whoever is still inactive gets a new date and the warning mails.
class ClearStaleUserDeletionDates < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE users SET deletion_date = NULL WHERE deletion_date IS NOT NULL")
  end

  # The cleared dates are not kept; the cleaner sets new ones.
  def down
  end
end
