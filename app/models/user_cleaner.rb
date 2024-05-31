# Deletes inactive users from the database.
# See [1] for a description of how the flow works.
# [1] https://github.com/MaMpf-HD/mampf/issues/410#issuecomment-2136875776
class UserCleaner
  # Returns all users who have been inactive for 6 months,
  # i.e. their last sign-in date is more than 6 months ago.
  def inactive_users
    User.where("last_sign_in_at < ?", 6.months.ago)
  end

  # Sets the deletion date for inactive users.
  #
  # This method finds all inactive users whose deletion date is nil (not set yet)
  # and updates their deletion date to be 40 days from the current date.
  def set_deletion_date_for_inactive_users
    inactive_users.where(deletion_date: nil).find_each do |user|
      user.update(deletion_date: Date.current + 40.days)
    end
  end

  # Deletes all users whose deletion date is in the past.
  #
  # The deletion date must have been set beforehand by calling
  # `set_deletion_date_for_inactive_users`.
  def delete_users_according_to_deletion_date
    deleted_count = 0
    User.where("deletion_date <= ?", Date.current).find_each do |user|
      next unless user.generic?

      user.destroy
      deleted_count += 1
    end
    puts "#{deleted_count} stale users deleted."
  end

  def handle_inactive_users
    set_deletion_date_for_inactive_users
    delete_users_according_to_deletion_date
  end
end
