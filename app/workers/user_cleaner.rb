# Deletes inactive users from the database.
# See [1] for a description of how the flow works on a high level.
#
# Users have a deletion_date field that is nil by default. It is set to a future
# date if the user has been inactive for too long (i.e. hasn't logged in).
# Before the deletion date is reached, we send warning mails. If users log in
# before the deletion date, that date is reset to nil such that the user is not
# deleted. If the user is still inactive on the deletion date, the user is
# ultimately deleted.
#
# [1] https://github.com/MaMpf-HD/mampf/issues/410#issuecomment-2136875776
class UserCleaner
  # The maximum number of users that can be deleted in one run.
  # This is equivalent to the maximum of number of deletion dates set in one run.
  #
  # This flag can be used to prevent too many mails from being sent at once.
  # Keep in mind that the mail server also handles other mails, e.g. notification
  # mails etc., so we might want to set the limit very low here such that our
  # mail server is not marked as "spam server".
  #
  # Note that this is just a soft limit, i.e. the actual number of deletion
  # warning mails sent on a given day might be higher than this number:
  # - If on a given day the cronjob is not run (for whatever reason),
  #   we have more users with a deletion date lying in the past than
  #   MAX_DELETIONS_PER_RUN. However, we don't send an additional mail once
  #   the user is deleted, so this shouldn't be a problem.
  # - Despite that there cannot be more than MAX_DELETIONS_PER_RUN users with the
  #   same deletion date, warning mails might be sent on the same date to users
  #   with varying deletion dates, since the 40-, 14-, 7- and 2-day warning mails
  #   can overlap temporally.
  MAX_DELETIONS_PER_RUN = 50

  # Returns all users who have been inactive for 6 months,
  # i.e. their last sign-in date is more than 6 months ago.
  def inactive_users
    User.where("last_sign_in_at < ?", 6.months.ago)
  end

  # Sets the deletion date for inactive users and sends an initial warning mail.
  #
  # This method finds all inactive users whose deletion date is nil (not set yet)
  # and updates their deletion date to be 40 days from the current date.
  #
  # The maximum number of deletion dates set in one run is limited by
  # MAX_DELETIONS_PER_RUN.
  def set_deletion_date_for_inactive_users
    inactive_users.where(deletion_date: nil)
                  .limit(MAX_DELETIONS_PER_RUN)
                  .find_each do |user|
      user.update(deletion_date: Date.current + 40.days)
      UserCleanerMailer.with(user: user).pending_deletion_email(40).deliver_later
    end
  end

  # Unsets the deletion date for users who have been active recently.
  #
  # This method finds all users whose deletion date is set and unsets it if the
  # user has been active in the last 6 months.
  #
  # Note that this method just serves as a safety measure. The deletion date
  # should be unset after every successful user sign-in, see the Warden callback
  # in `config/initializers/after_sign_in.rb`. If for some reason, the callback
  # does not work, this method will prevent active users from being deleted
  # as a last resort.
  def unset_deletion_date_for_recently_active_users
    inactive_users_cached = inactive_users

    User.where.not(deletion_date: nil).find_each do |user|
      next if inactive_users_cached.include?(user)

      user.update(deletion_date: nil)
    end
  end

  # Deletes all users whose deletion date is in the past or present.
  #
  # Technically, there should never be users with a deletion date in the past
  # since the cron job is run daily and should delete users on the day of their
  # deletion date. Should the cron job not run for some reason, we also delete
  # users with a deletion date in the past via this method.
  #
  # The deletion date for the users must have been set beforehand by calling
  # `set_deletion_date_for_inactive_users`.
  def delete_users_according_to_deletion_date!
    num_deleted_users = 0

    User.where("deletion_date <= ?", Date.current).find_each do |user|
      next unless user.generic?

      user.destroy
      num_deleted_users += 1
    end

    Rails.logger.info("UserCleaner deleted #{num_deleted_users} stale users")
  end

  # Sends additional warning mails to users whose deletion date is near.
  #
  # In addition to the initial warning mail 40 days before deletion, this method
  # sends warning mails 14, 7 and 2 days before the account is deleted.
  def send_additional_warning_mails
    User.where.not(deletion_date: nil).find_each do |user|
      num_days_until_deletion = (user.deletion_date - Date.current).to_i

      if [14, 7, 2].include?(num_days_until_deletion)
        UserCleanerMailer.with(user: user)
                         .pending_deletion_email(num_days_until_deletion)
                         .deliver_later
      end
    end
  end

  # Handles inactive users according to the deletion policy documented
  # in the UserCleaner class description. Brief: users that haven't logged in
  # to MaMpf for too long will be deleted.
  def handle_inactive_users!
    set_deletion_date_for_inactive_users
    unset_deletion_date_for_recently_active_users
    delete_users_according_to_deletion_date!

    send_additional_warning_mails
  end
end
