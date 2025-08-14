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

        ids_to_filter = params[:term_ids].dup

        # If the active term is selected, we also include records without a term
        # (e.g., term-independent lectures).
        ids_to_filter << nil if Term.active.try(:id).to_s.in?(ids_to_filter)

        scope.where(term_id: ids_to_filter)
      end
    end
  end
end
