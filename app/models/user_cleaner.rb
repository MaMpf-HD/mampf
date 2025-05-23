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
  MAX_DELETIONS_PER_RUN = ENV.fetch("MAX_DELETIONS_PER_RUN").to_i

  # The threshold for inactive users. Users who have not logged in for this time
  # are considered inactive.
  INACTIVE_USER_THRESHOLD = 6.months

  # Returns all users who have been inactive for INACTIVE_USER_THRESHOLD months,
  # i.e. their last sign-in date is more than INACTIVE_USER_THRESHOLD months ago.
  #
  # Users without a current_sign_in_at date are also considered inactive. This is
  # the case for users who have never logged in since PR #553 was merged.
  #
  # Edge cases for registration (that refine the above statements):
  # - A user might have registered but never actually logged in (confirmed their
  #   email address). In this case, we don't look at the current_sign_in_at date
  #   (as this one is still nil), but at the confirmation_sent_at date to
  #   determine if the user is considered inactive.
  # - Another edge case is when users have registered and confirmed their mail,
  #   but never logged in after that. In this case, current_sign_in_at is indeed nil,
  #   but the user should only be considered inactive if the confirmation_sent_at
  #   date is older than the threshold.
  def inactive_users
    threshold = INACTIVE_USER_THRESHOLD
    User.confirmed.and(
      User.inactive_for(threshold)
      .or(User.no_sign_in_data.confirmation_sent_before(threshold))
    ).or(User.unconfirmed.confirmation_sent_before(threshold))
  end

  # Returns all users who have been active in the last INACTIVE_USER_THRESHOLD months,
  # i.e. their last sign-in date is less than INACTIVE_USER_THRESHOLD months ago.
  def active_users
    User.active_recently(INACTIVE_USER_THRESHOLD)
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
      user.deletion_date = Date.current + 40.days

      # Even if the user record is invalid, we still want to set the
      # deletion date, that's why we skip validation here.
      user.save(validate: false)

      if user.generic?
        UserCleanerMailer.pending_deletion_email(user.email, user.locale, 40)
                         .deliver_later
      end
    end
  end

  # Unsets the deletion date for users who have been active recently.
  #
  # This method finds all users whose deletion date is set and unsets it if the
  # user has been active recently.
  #
  # Note that this method just serves as a safety measure. The deletion date
  # should be unset after every successful user sign-in, see the Warden callback
  # in `config/initializers/after_sign_in.rb`. If for some reason, the callback
  # does not work, this method will prevent active users from being deleted
  # as a last resort.
  def unset_deletion_date_for_recently_active_users
    active_users.where.not(deletion_date: nil).find_each do |user|
      user.deletion_date = nil
      user.save(validate: false)
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
  #
  # Even after having called this method, there might still exist users with a
  # deletion date in the future, as we only delete generic users.
  def delete_users_according_to_deletion_date!
    num_deleted_users = 0
    num_intended_to_delete = 0

    User.where(deletion_date: ..Date.current).find_each do |user|
      next unless user.generic?

      UserCleanerMailer.deletion_email(user.email, user.locale).deliver_later
      num_intended_to_delete += 1

      if user.destroy
        num_deleted_users += 1
      else
        Rails.logger.info("UserCleaner failed to destroy user #{user.id}")
        UserCleanerMailer.destroy_failed_email(user).deliver_later
      end
    end

    Rails.logger.info("UserCleaner deleted #{num_deleted_users} stale users" \
      + " (intended to delete: #{num_intended_to_delete})")
  end

  # Sends additional warning mails to users whose deletion date is near.
  #
  # In addition to the initial warning mail 40 days before deletion, this method
  # sends warning mails 14, 7 and 2 days before the account is deleted.
  def send_additional_warning_mails
    User.where.not(deletion_date: nil).find_each do |user|
      next unless user.generic?

      num_days_until_deletion = (user.deletion_date - Date.current).to_i

      if [14, 7, 2].include?(num_days_until_deletion)
        UserCleanerMailer
          .pending_deletion_email(user.email, user.locale, num_days_until_deletion)
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
