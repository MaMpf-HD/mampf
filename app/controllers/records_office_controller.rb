# Lets the records office read every lecture of a term: its groups, how many
# have registered for them and how full they are. It only reads.
class RecordsOfficeController < ApplicationController
  authorize_resource class: false
  helper RecordsOfficeHelper

  def current_ability
    @current_ability ||= RecordsOfficeAbility.new(current_user)
  end

  def index
    @term = Term.from_dashboard_param(params[:term]) || Term.active || Term.chronological.last
    @term_options = Term.chronological.reverse.map { |term| [term.to_label, term.dashboard_param] }
    @overview = RecordsOffice::TermOverview.new(@term)
  end
end
