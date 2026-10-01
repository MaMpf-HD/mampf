# Shows the dean's office every lecture of a term with its groups, how many
# students they have and how far their registration is, without asking each
# teacher.
class DeansOfficeController < ApplicationController
  authorize_resource class: false
  helper DeansOfficeHelper

  def current_ability
    @current_ability ||= DeansOfficeAbility.new(current_user)
  end

  def index
    @term = Term.from_dashboard_param(params[:term]) || Term.active || Term.chronological.last
    @term_options = Term.chronological.reverse.map { |term| [term.to_label, term.dashboard_param] }
    @overview = DeansOffice::TermOverview.new(@term)
    @by_phase = params[:order] == "phase"
  end
end
