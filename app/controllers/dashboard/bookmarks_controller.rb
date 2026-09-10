module Dashboard
  # Adds or removes a lecture from the student's dashboard bookmarks, straight
  # from the lecture search on the dashboard.
  #
  # A bookmark is a plain lecture subscription - the same thing the "Bookmarked"
  # band on the dashboard is built from (see User#current_bookmarked_lectures).
  #
  # The response re-renders the dashboard's lecture bands as a Turbo Stream, so
  # the "Bookmarked" section above the search updates in place. The search
  # result's own button is kept in sync on the client (see the bookmark and
  # bookmark-removal Stimulus controllers).
  class BookmarksController < ApplicationController
    before_action :set_lecture

    def create
      return head(:not_found) unless @lecture
      return head(:forbidden) unless bookmarkable?(@lecture)

      current_user.subscribe_lecture!(@lecture)
      # favorite lectures and the navbar are cached against the user, so the
      # subscription change has to touch the user to show up (mirrors
      # ProfileController#star_lecture)
      current_user.touch
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

      # Re-renders the term-dependent lecture bands. Mirrors the setup in
      # MainController#start; kept scoped to the semester the search's hidden
      # term field points at, passed through as `?term=`.
      def render_board
        term = Dashboard::TermSelector.selected(params)
        @enrolled_lectures = current_user.current_enrolled_lectures(term)
        @bookmarked_lectures = current_user.current_bookmarked_lectures(term)
        @talks = current_user.talks.includes(lecture: :term)
                             .select do |talk|
                               talk.lecture.term_id == term&.id &&
                                 talk.visible_for_user?(current_user)
                             end
                             .sort_by(&:position)
        @lecture_activity = Dashboard::LectureActivity.new(
          user: current_user,
          lectures: @enrolled_lectures + @bookmarked_lectures
        )

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "dashboardLectureCards", partial: "main/start/lecture_cards"
            )
          end
        end
      end

      # Mirrors the guard in ProfileController#subscribe_lecture: an unpublished
      # lecture, or one behind a passphrase the user has not already cleared, is
      # not something to bookmark in a single click.
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
