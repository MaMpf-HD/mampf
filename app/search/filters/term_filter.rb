# Filters a scope by associated terms, with special handling for the active term.
#
# This filter is skipped if the 'all_terms' parameter is set to '1' or if
# no specific term IDs are provided.
#
# It includes a special behavior: if the currently active term is among the
# selected `term_ids`, the filter will also include records that have no
# associated term (`term_id` is `nil`). Otherwise, it filters strictly by
# the provided `term_ids`.
module Search
  module Filters
    class TermFilter < BaseFilter
      def call
        return scope if skip_filter?(all_param: :all_terms, ids_param: :term_ids)

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
end
