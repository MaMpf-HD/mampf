# Clears the deletion dates set before the user cleaner was paused. They have
# long passed, so its first run would delete those accounts without another
# warning.
class ClearStaleUserDeletionDates < ActiveRecord::Migration[8.0]
  class User < ApplicationRecord
  end

  def up
    # rubocop:disable Rails/SkipsModelValidations
    User.where.not(deletion_date: nil).update_all(deletion_date: nil)
    # rubocop:enable Rails/SkipsModelValidations
  end

  # The cleared dates are not kept; the cleaner sets new ones.
  def down
  end
end
