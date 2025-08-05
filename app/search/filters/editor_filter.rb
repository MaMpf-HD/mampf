# Filters a scope to include only records associated with specific editors.
#
# This filter is skipped if the 'all_editors' parameter is set to '1' or if
# no editor IDs are provided in the `editor_ids` parameter.
#
# When active, it joins the `editors` association and filters by the given
# user IDs.
module Search
  module Filters
    class EditorFilter < BaseFilter
      def call
        return scope if skip_filter?(all_param: :all_editors, ids_param: :editor_ids)

        scope.joins(:editors)
             .where(users: { id: params[:editor_ids] })
      end
    end
  end
end
