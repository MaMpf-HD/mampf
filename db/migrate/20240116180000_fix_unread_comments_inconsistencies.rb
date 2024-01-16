# Fixes the unread_comments flag for all users. Unintended behavior was
# introduced in pull request #515. Migration introduced in #587.
# Behavior fixed in #585.
#
# This migration is generally *not* idempotent since users might have interacted
# with the website since the migration was run and thus they will probably have
# different unread comments flags as the ones at the time of the migration.
#
# This migration is not reversible as we don't store the previous state of
# the unread_comments flag.
class FixUnreadCommentsInconsistencies < ActiveRecord::Migration[7.0]
  def up
    num_fixed_users = 0

    User.find_each do |user|
      had_user_unread_comments = user.unread_comments # boolean
      has_user_unread_comments = user_unread_comments?(user)

      has_flag_changed = (had_user_unread_comments != has_user_unread_comments)
      user.update(unread_comments: has_user_unread_comments) if has_flag_changed
      num_fixed_users += 1 if has_flag_changed
    end

    Rails.logger.debug { "Ran through #{User.count} users (unread comments flag)" }
    Rails.logger.debug { "Fixed #{num_fixed_users} users (unread comments flag)" }
  end

  # Checks and returns whether the user has unread comments.
  def user_unread_comments?(user)
    # Check for unread comments -- directly via Reader
    readers = Reader.where(user: user)
    readers.each do |reader|
      thread = Commontator::Thread.find_by(id: reader.thread_id)
      next if thread.nil?

      latest_thread_comment_by_any_user = thread.comments.max_by(&:created_at)
      next if latest_thread_comment_by_any_user.blank?

      latest_thread_comment_time = latest_thread_comment_by_any_user.created_at
      has_user_unread_comments = reader.updated_at < latest_thread_comment_time

      return true if has_user_unread_comments
    end

    # User might still have unread comments but no related Reader objects
    # -> Check for unread comments -- via Media
    unseen_media = user.subscribed_media_with_latest_comments_not_by_creator.select do |m|
      m[:medium].visible_for_user?(user)
    end
    unseen_media.present?
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
