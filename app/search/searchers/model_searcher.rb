# This service class orchestrates the process of building a complex, filterable,
# and sortable database query for a given model. It uses a set of filter
# classes to apply various conditions and then ensures the results are unique
# and correctly ordered.
module Search
  module Searchers
    class ModelSearcher
      attr_reader :model_class, :params, :filter_classes, :user, :orderer_class

      # Initializes the search service.
      #
      # @param model_class [Class] The ActiveRecord model class to be searched (e.g., Course).
      # @param params [Hash] The search parameters from the controller.
      # @param filter_classes [Array<Class>] An array of filter classes to be applied.
      # full-text search query.
      # @param user [User] The current user, for permission-sensitive filters.
      # @param orderer_class [Class] An optional class to handle ordering.
      def initialize(model_class, params, filter_classes, user:, orderer_class: nil)
        @model_class = model_class
        @params = params.to_h.with_indifferent_access
        @filter_classes = filter_classes
        @user = user
        @orderer_class = orderer_class || Orderers::SearchOrderer
      end

      # Executes the search by applying filters and ordering.
      #
      # @return [ActiveRecord::Relation] The resulting query object.
      def call
        scope = model_class.all

        # Apply all registered filters to the scope.
        scope = Search::Filters::FilterApplier.call(scope: scope, filter_classes: filter_classes,
                                                    params: params, user: user)

        # Ensure the results are unique, as joins can create duplicates.
        scope = scope.distinct

        # Use the specified orderer class.
        orderer_class.call(model_class: model_class,
                           scope: scope,
                           search_params: params)
      end
    end
  end
end
