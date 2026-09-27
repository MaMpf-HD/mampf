module Dashboard
  # Loads the dashboard's term-dependent lecture bands (`load_board`, shared
  # with MainController#start) and re-renders them as a Turbo Stream
  # (`render_board`, used after bookmarking or dismissing a notice).
  module BoardRenderer
    extend ActiveSupport::Concern

    private

      # Populates @selected_term and @board (see Dashboard::Board).
      def load_board(term)
        @selected_term = term
        @board = Dashboard::Board.new(user: current_user, term: term)
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
