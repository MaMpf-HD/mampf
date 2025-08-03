# Filters a scope to include only records associated with specific editors.
#
# This filter is skipped if the 'all_editors' parameter is set to '1' or if
# no editor IDs are provided in the `editor_ids` parameter.
#
# When active, it joins the `editors` association and filters by the given
# user IDs.
module Filters
  class EditorFilter < BaseFilter
    def call
      # This single check handles nil, [], [""], [nil], etc.
      no_specific_editors = params[:editor_ids].to_a.compact_blank.empty?

      return scope if params[:all_editors] == "1" || no_specific_editors

      scope.joins(:editors)
           .where(users: { id: params[:editor_ids] })
    end
  end
end
