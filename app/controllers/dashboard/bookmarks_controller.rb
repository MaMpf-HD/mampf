module Dashboard
  # Bookmarks a lecture from the dashboard search (stored as a LectureBookmark).
  class BookmarksController < ApplicationController
    include Dashboard::BoardRenderer

    before_action :set_lecture

    def create
      return head(:not_found) unless @lecture
      return head(:forbidden) unless current_user.unlock_lecture!(@lecture)

      render_board
    end

    def destroy
      return head(:not_found) unless @lecture

      current_user.unbookmark_lecture!(@lecture)
      current_user.touch
      render_board
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
      end
  end
end
