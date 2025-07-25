module FilterableByEditor
  extend ActiveSupport::Concern

  included do
    # This scope is required by the filter logic.
    # Any model including this concern must have this association.
    scope :by_editors, lambda { |editor_ids|
      return all if editor_ids.blank?

      joins(:editable_user_joins).where(editable_user_joins: { user_id: editor_ids }).distinct
    }
  end

  class_methods do
    private

      # This is the actual filter implementation.
      def apply_editor_filter(scope, params)
        return scope if params[:all_editors] == "1"

        scope.by_editors(params[:editor_ids])
      end
  end
end
