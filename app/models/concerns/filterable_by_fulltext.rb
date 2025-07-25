module FilterableByFulltext
  extend ActiveSupport::Concern

  included do
    class_attribute :fulltext_parameter, default: :fulltext
  end

  class_methods do
    private

      # Assumes the model has a pg_search_scope named :search_by_title
      def apply_fulltext_filter(scope, params)
        search_term = params[fulltext_parameter]
        return scope if search_term.blank?

        scope.search_by_title(search_term).with_pg_search_rank
      end
  end
end
