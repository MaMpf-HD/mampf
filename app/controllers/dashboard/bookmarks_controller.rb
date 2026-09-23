module Dashboard
  # Bookmarks (= lecture subscriptions) a lecture from the dashboard search.
  class BookmarksController < ApplicationController
    include Dashboard::BoardRenderer

    before_action :set_lecture

    def create
      return head(:not_found) unless @lecture
      return head(:forbidden) unless @lecture.bookmarkable_by?(current_user)

      current_user.subscribe_lecture!(@lecture)
      current_user.touch # busts the cached navbar/favorites (see ProfileController#star_lecture)
      render_board
    end

    def destroy
      return head(:not_found) unless @lecture

      current_user.unsubscribe_lecture!(@lecture)
      current_user.touch
      render_board
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
      end
  end
end
