module Dashboard
  # Re-renders the dashboard's term-dependent lecture bands as a Turbo Stream.
  # Shared by the controllers that change a lecture's place on the board
  # (bookmarking, dismissing a rejected registration's notice).
  module RendersBoard
    extend ActiveSupport::Concern

    private

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
  end
end
