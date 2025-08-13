# This service class orchestrates the process of building a complex, filterable,
# and sortable database query for a given model. It uses a set of filter
# classes to apply various conditions and then ensures the results are unique
# and correctly ordered.
module Search
  module Searchers
    class ModelSearcher
      attr_reader :model_class, :user, :config

      # @param model_class [Class] The ActiveRecord model class to be searched.
      # @param user [User] The current user, for permission-sensitive filters.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      def self.call(model_class:, user:, config:)
        new(model_class: model_class, user: user, config: config).call
      end

      def initialize(model_class:, user:, config:)
        @model_class = model_class
        @user = user
        @config = config
      end

      # Executes the search by applying filters and ordering.
      #
      # @return [ActiveRecord::Relation] The resulting query object.
      def call
        # Use a local variable for the orderer, providing a default if nil.
        orderer_class = config.orderer_class || Orderers::SearchOrderer

        # Apply all registered filters to the scope.
        scope = Filters::FilterApplier.apply(scope: model_class.all,
                                             user: user,
                                             config: config)

        # Ensure the results are unique, as joins can create duplicates.
        scope = scope.distinct

        # Use the specified orderer class to sort the results.
        orderer_class.call(model_class: model_class,
                           scope: scope,
                           search_params: config.params)
      end
    end
  end
end
