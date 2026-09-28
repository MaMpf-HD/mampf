module Dashboard
  # Loads the dashboard's term-dependent lecture bands (`load_board`, shared
  # with MainController#start) and re-renders them as a Turbo Stream
  # (`render_board`, used after bookmarking or dismissing a notice).
  module BoardRenderer
    extend ActiveSupport::Concern

    TERM_COOKIE = :dashboard_term

    private

      # The term to show on the dashboard (see Dashboard::TermSelector.selected).
      # An explicit ?term= pick is stored in a cookie, so the dashboard opens
      # on that term next time.
      def selected_dashboard_term
        term = Dashboard::TermSelector.selected(params, cookies[TERM_COOKIE])
        remember_dashboard_term(term) if params[:term].present? && term
        term
      end

      def remember_dashboard_term(term)
        cookies[TERM_COOKIE] = { value: term.dashboard_param, expires: 1.year,
                                 httponly: true, same_site: :lax }
      end

      # Populates @selected_term and @board (see Dashboard::Board).
      def load_board(term)
        @selected_term = term
        @board = Dashboard::Board.new(user: current_user, term: term)
      end

      def render_board
        load_board(selected_dashboard_term)

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
