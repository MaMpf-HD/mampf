module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model
  end

  class_methods do
    def search_by(search_params)
      build_search_scope(search_params)
        .then { |scope| apply_ordering(scope) }
    end

    private

      def build_search_scope(search_params)
        search_filters.reduce(all) do |scope, filter_method|
          send(filter_method, scope, search_params)
        end
      end

      def apply_ordering(scope)
        scope.order(default_search_order)
      end

      # Override these in each model
      def search_filters
        raise(NotImplementedError, "Define search_filters in #{name}")
      end

      def default_search_order
        Arel.sql("LOWER(unaccent(title)) ASC")
      end
  end
end
