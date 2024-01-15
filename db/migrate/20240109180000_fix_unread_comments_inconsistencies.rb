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
    users = User.all
    num_fixed_users = 0

    users.find_each do |user|
      was_user_fixed = fix_unread_comments_flag(user)
      num_fixed_users += 1 if was_user_fixed
    end

    Rails.logger.debug { "Ran through #{users.length} users (unread comments flag)" }
    Rails.logger.debug { "Fixed #{num_fixed_users} users (unread comments flag)" }
  end

  # Fixes the unread_comments flag for a given user.
  # Returns true if the flag needed a change (and was changed), false otherwise.
  def fix_unread_comments_flag(user)
    readers = Reader.where(user_id: user.id)
    return false if readers.blank?

    had_user_unread_comments = user.unread_comments
    has_user_unread_comments = false

    readers.each do |reader|
      thread = Commontator::Thread.find_by(id: reader.thread_id)
      next if thread.blank? # thread_id should never be nil, just to be sure

      latest_thread_comment_by_any_user = thread.comments.max_by(&:created_at)
      next if latest_thread_comment_by_any_user.blank?

      latest_thread_comment_time = latest_thread_comment_by_any_user.created_at
      has_user_unread_comments = reader.updated_at < latest_thread_comment_time

      if has_user_unread_comments
        # user has unread comments, so no need to check other threads
        break
      end

      user.update(unread_comments: has_user_unread_comments)
    end

    had_user_unread_comments != has_user_unread_comments
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
