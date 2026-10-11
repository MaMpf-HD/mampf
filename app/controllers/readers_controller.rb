# ReadersController
class ReadersController < ApplicationController
  # no authorization for this controller

  def update
    @thread = Commontator::Thread.find_by(id: reader_params[:thread_id])
    return unless @thread

    @reader = Reader.find_or_create_by(user: current_user,
                                       thread: @thread)
    @reader.touch
    @anything_left = anything_left?
    current_user.update(unread_comments: false) unless @anything_left
  end

  def update_all
    @lecture = Lecture.find_by(id: params[:lecture_id]) if params[:lecture_id]
    threads = commented_media.map(&:commontator_thread)
    existing_readers = Reader.where(user: current_user, thread: threads)
    missing_thread_ids = threads.map(&:id) - existing_readers.pluck(:thread_id)
    new_readers = missing_thread_ids.map do |t|
      Reader.new(thread_id: t, user: current_user)
    end
    Reader.import new_readers
    Reader.where(user: current_user, thread: threads).touch_all
    @anything_left = @lecture.present? && anything_left?
    current_user.update(unread_comments: false) unless @anything_left
  end

  private

    # The same media MainController#comments lists, so that marking all as
    # read on a page filtered to a lecture leaves the other lectures unread.
    def commented_media
      return current_user.subscribed_commentable_media_with_comments unless @lecture

      Dashboard::LectureActivity.new(user: current_user, lectures: [@lecture])
                                .media_with_unread_comments
    end

    def anything_left?
      current_user.subscribed_media_with_latest_comments_not_by_creator.any? do |m|
        (Reader.find_by(user: current_user, thread: m[:thread])
              &.updated_at || 1000.years.ago) < m[:latest_comment].created_at
      end
    end

    def reader_params
      params.permit(:thread_id)
    end
end
