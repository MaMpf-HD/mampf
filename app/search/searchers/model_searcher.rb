# This service class orchestrates the process of building a complex, filterable,
# and sortable database query for a given model. It uses a set of filter
# classes to apply various conditions and then ensures the results are unique
# and correctly ordered.
module Search
  module Searchers
    class ModelSearcher
      attr_reader :model_class, :search_params, :filter_classes, :user, :orderer_class

      # @param model_class [Class] The ActiveRecord model class to be searched (e.g., Course).
      # @param search_params [Hash] The search parameters from the controller.
      # @param filter_classes [Array<Class>] An array of filter classes to be applied.
      # @param user [User] The current user, for permission-sensitive filters.
      # @param orderer_class [Class] An optional class to handle ordering.
      def self.call(model_class:, search_params:, filter_classes:, user:, orderer_class: nil)
        new(model_class: model_class, search_params: search_params,
            filter_classes: filter_classes, user: user,
            orderer_class: orderer_class).call
      end

      def initialize(model_class:, search_params:, filter_classes:, user:, orderer_class:)
        @model_class = model_class
        @search_params = search_params.to_h.with_indifferent_access
        @filter_classes = filter_classes
        @user = user
        @orderer_class = orderer_class || Orderers::SearchOrderer
      end

      # Executes the search by applying filters and ordering.
      #
      # @return [ActiveRecord::Relation] The resulting query object.
      def call
        # Apply all registered filters to the scope.
        scope = Search::Filters::FilterApplier.call(scope: model_class.all,
                                                    filter_classes: filter_classes,
                                                    params: search_params, user: user)

        # Ensure the results are unique, as joins can create duplicates.
        scope = scope.distinct

        # Use the specified orderer class.
        orderer_class.call(model_class: model_class,
                           scope: scope,
                           search_params: search_params)
      end
    end
  end
end
