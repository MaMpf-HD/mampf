module Dashboard
  # Switches the dashboard to a different term.
  class TermsController < ApplicationController
    include Dashboard::RendersBoard

    def show
      @available_terms = Dashboard::TermSelector.terms
      @selected_term = Dashboard::TermSelector.selected(params)

      load_board(@selected_term)

      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
