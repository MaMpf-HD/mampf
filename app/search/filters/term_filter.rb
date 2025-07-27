module Filters
  class TermFilter < BaseFilter
    def call
      return scope if params[:all_terms] == "1" || params[:term_ids].blank?

      # Add lectures without a term if the active term is selected
      if Term.active.try(:id).to_s.in?(params[:term_ids])
        scope.left_outer_joins(:term)
             .where(term_id: params[:term_ids] + [nil])
      else
        scope.where(term_id: params[:term_ids])
      end
    end
  end
end
