module Dashboard
  # Switches the dashboard to a different term.
  class TermsController < ApplicationController
    include Dashboard::BoardRenderer

    def show
      @available_terms = Dashboard::TermSelector.terms
      @selected_term = Dashboard::TermSelector.selected(params)

      load_board(@selected_term)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path(term: params[:term]) }
      end
    end
  end
end
