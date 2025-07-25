module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model
  end

  class_methods do
    def search_by(search_params)
      scope = build_search_scope(search_params)
      apply_ordering(scope, search_params)
    end

    private

      def build_search_scope(search_params)
        search_filters.reduce(all) do |scope, filter_method|
          # It finds the apply_* methods from the included filter concerns
          send(filter_method, scope, search_params)
        end
      end

      def apply_ordering(scope, search_params)
        # If a full-text search is active, let pg_search order by relevance.
        return scope if search_params[:fulltext].present?

        # Otherwise, apply the model's specific default sort order.
        order_expression = default_search_order
        scope.select(Arel.star, order_expression).order(order_expression)
      end

      # Override these in each model
      def search_filters
        raise(NotImplementedError, "Define search_filters in #{name}")
      end

      def default_search_order
        raise(NotImplementedError, "Define default_search_order in #{name}")
      end
  end
end
