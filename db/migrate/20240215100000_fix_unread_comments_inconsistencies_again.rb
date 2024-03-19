# Fixes the unread_comments flag for all users. Unintended behavior was
# introduced in pull request #515. Behavior fixed in #585
# A migration was introduced in #587, but it turned out it contained a bug.
# This migration here is a fix for the migration in #587.
#
# This migration is generally *not* idempotent since users might have interacted
# with the website since the migration was run and thus they will probably have
# different unread comments flags as the ones at the time of the migration.
#
# This migration is not reversible as we don't store the previous state of
# the unread_comments flag.
class FixUnreadCommentsInconsistenciesAgain < ActiveRecord::Migration[7.0]
  def up
    num_fixed_users = 0

    User.find_each do |user|
      had_user_unread_comments = user.unread_comments # boolean
      has_user_unread_comments = user_unread_comments?(user)

      has_flag_changed = (had_user_unread_comments != has_user_unread_comments)
      user.update(unread_comments: has_user_unread_comments) if has_flag_changed
      num_fixed_users += 1 if has_flag_changed
    end

    Rails.logger.warn { "Ran through #{User.count} users (unread comments flag again)" }
    Rails.logger.warn { "Fixed #{num_fixed_users} users (unread comments flag again)" }
  end

  # Checks and returns whether the user has unread comments.
  def user_unread_comments?(user)
    # see the method "comments" in app/controllers/main_controller.rb
    unseen_media = user.subscribed_media_with_latest_comments_not_by_creator
    unseen_media.select! do |m|
      (Reader.find_by(user: user, thread: m[:thread])
            &.updated_at || 1000.years.ago) < m[:latest_comment].created_at &&
        m[:medium].visible_for_user?(user)
    end

    unseen_media.present?
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
