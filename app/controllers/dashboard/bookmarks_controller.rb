module Dashboard
  # Bookmarks (= lecture subscriptions) a lecture from the dashboard search.
  class BookmarksController < ApplicationController
    include Dashboard::RendersBoard

    before_action :set_lecture

    def create
      return head(:not_found) unless @lecture
      return head(:forbidden) unless bookmarkable?(@lecture)

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

      # Mirrors ProfileController#subscribe_lecture's guard.
      def bookmarkable?(lecture)
        return true if lecture.in?(current_user.lectures)
        unless lecture.published? || current_user.admin ||
               lecture.edited_by?(current_user)
          return false
        end

        lecture.passphrase.blank? ||
          LectureMembership.exists?(user: current_user, lecture: lecture)
      end
  end
end
