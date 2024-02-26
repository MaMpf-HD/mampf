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
    # 🛑 This migration contains a bug, please don't use it again. Instead,
    # refer to the migration in 20240215100000_fix_unread_comments_inconsistencies_again.rb.
    #
    # 💡 Explanation of the bug:
    # The bug resides within the method `user_unread_comments?`. It was supposed
    # to reflect the logic of the method `comments` in app/controllers/main_controller.rb:
    #
    #  def comments
    #    @media_comments = current_user.subscribed_media_with_latest_comments_not_by_creator
    #    @media_comments.select! do |m|
    #      (Reader.find_by(user: current_user, thread: m[:thread])
    #            &.updated_at || 1000.years.ago) < m[:latest_comment].created_at &&
    #        m[:medium].visible_for_user?(current_user)
    #    end
    #    @media_array = Kaminari.paginate_array(@media_comments)
    #                           .page(params[:page]).per(10)
    #  end
    #
    # The method `user_unread_comments?` in this migration, however, does not
    # reflect the logic of the method `comments` in app/controllers/main_controller.rb
    # precisely. Consider what happens when for each reader instance, the
    # check reader.updated_at < latest_thread_comment_time is false. In this case,
    # we don't encounter an early "return true" and therefore go on with the second
    # part. There, we want to check if there are any *unseen* media. What we actually do
    # is to check if there are any media with comments (that are not by the creator
    # and that are visible to the user). But we missed the part where we check if
    # the user has already seen these comments, i.e. an additional reader query
    # is missing. This is why suddenly, many more people encounter the original
    # issue after having run this migration.
    #
    # This migration took ~40 minutes to run for ~7000 users at 2024-02-15, 0:40.
    raise ActiveRecord::IrreversibleMigration

    # For archive reasons, here is the original code:

    # num_fixed_users = 0

    # User.find_each do |user|
    #   had_user_unread_comments = user.unread_comments # boolean
    #   has_user_unread_comments = user_unread_comments?(user)

    #   has_flag_changed = (had_user_unread_comments != has_user_unread_comments)
    #   user.update(unread_comments: has_user_unread_comments) if has_flag_changed
    #   num_fixed_users += 1 if has_flag_changed
    # end

    # Rails.logger.warn { "Ran through #{User.count} users (unread comments flag)" }
    # Rails.logger.warn { "Fixed #{num_fixed_users} users (unread comments flag)" }
  end

  # Checks and returns whether the user has unread comments.
  # def user_unread_comments?(user)
  #   # Check for unread comments -- directly via Reader
  #   readers = Reader.where(user: user)
  #   readers.each do |reader|
  #     thread = Commontator::Thread.find_by(id: reader.thread_id)
  #     next if thread.nil?

  #     latest_thread_comment_by_any_user = thread.comments.max_by(&:created_at)
  #     next if latest_thread_comment_by_any_user.blank?

  #     latest_thread_comment_time = latest_thread_comment_by_any_user.created_at
  #     has_user_unread_comments = reader.updated_at < latest_thread_comment_time

  #     return true if has_user_unread_comments
  #   end

  #   # User might still have unread comments but no related Reader objects
  #   # -> Check for unread comments -- via Media
  #   unseen_media = user.subscribed_media_with_latest_comments_not_by_creator.select do |m|
  #     m[:medium].visible_for_user?(user)
  #   end
  #   unseen_media.present?
  # end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
