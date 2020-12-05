# ReadersController
class ReadersController < ApplicationController

  def update
    @thread = Commontator::Thread.find_by_id(reader_params[:thread_id])
    return unless @thread
    @reader = Reader.find_or_create_by(user: current_user,
                                       thread: @thread)
    @reader.touch
    @anything_left = current_user.media_latest_comments.any? do |m|
      (Reader.find_by(user: current_user, thread: m[:thread])
            &.updated_at || (Time.now - 1000.years)) < m[:latest_comment].created_at
    end
    current_user.update(unread_comments: false) unless @anything_left
  end

  def update_all
    threads = current_user.subscribed_commentable_media_with_comments
                          .map(&:commontator_thread)
    existing_readers = Reader.where(user: current_user, thread: threads)
    missing_thread_ids = threads.map(&:id) - existing_readers.pluck(:thread_id)
    new_readers = []
    missing_thread_ids.each do |t|
      new_readers << Reader.new(thread_id: t, user: current_user)
    end
    Reader.import new_readers
    Reader.where(user: current_user, thread: threads)
          .update_all(updated_at: Time.now)
    current_user.update(unread_comments: false)
  end

  private

  def reader_params
    params.permit(:thread_id)
  end
end