module Search
  module Filters
    # Takes a scope and applies a series of filters to it, based on a provided
    # configuration.
    class FilterApplier
      # Applies each filter class from the configuration to the scope.
      #
      # @param scope [ActiveRecord::Relation] The initial scope to be filtered.
      # @param user [User] The current user, for permission-sensitive filters.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      # @return [ActiveRecord::Relation] The filtered scope.
      def self.apply(scope:, user:, config:)
        config.filters.reduce(scope) do |current_scope, filter_class|
          # Pass the necessary parts of the config to each individual filter.
          filter_class.apply(scope: current_scope,
                             params: config.params,
                             user: user)
        end
      end
    end
  end
end
