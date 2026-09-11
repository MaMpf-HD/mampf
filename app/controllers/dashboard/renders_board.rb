module Dashboard
  # Loads the dashboard's term-dependent lecture bands and, on top of that,
  # re-renders them as a Turbo Stream. `load_board` is shared with
  # MainController's initial page render; `render_board` is used by the
  # controllers that change a lecture's place on the board afterwards
  # (bookmarking, dismissing a rejected registration's notice).
  module RendersBoard
    extend ActiveSupport::Concern

    private

      # Populates the board's term-dependent instance variables:
      # @enrolled_lectures, @bookmarked_lectures, @talks, @lecture_activity.
      def load_board(term)
        @enrolled_lectures = current_user.current_enrolled_lectures(term)
        @bookmarked_lectures = current_user.current_bookmarked_lectures(
          term, enrolled: @enrolled_lectures
        )
        @talks = current_user.talks.includes(lecture: :term)
                             .select do |talk|
                               talk.lecture.term_id == term&.id &&
                                 talk.visible_for_user?(current_user)
                             end
                             .sort_by(&:position)

        # Gathered once for the whole board: every card asks the same two
        # questions of it, and asking them per card would multiply the
        # queries by the number of cards.
        @lecture_activity = Dashboard::LectureActivity.new(
          user: current_user,
          lectures: @enrolled_lectures + @bookmarked_lectures
        )
      end

      def render_board
        load_board(Dashboard::TermSelector.selected(params))

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "dashboardLectureCards", partial: "main/start/lecture_cards"
            )
          end
        end
      end
  end
end
