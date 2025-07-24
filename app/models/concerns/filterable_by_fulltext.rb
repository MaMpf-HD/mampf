module FilterableByFulltext
  extend ActiveSupport::Concern

  class_methods do
    private

      # Assumes the model has a pg_search_scope named :search_by_title
      def apply_fulltext_filter(scope, params)
        return scope if params[:fulltext].blank?

        scope.search_by_title(params[:fulltext]).with_pg_search_rank
      end
  end
end
