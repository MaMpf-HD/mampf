module Search
  module Filters
    # This service class takes a scope and applies a series of filters to it,
    # based on a provided configuration.
    class FilterApplier
      attr_reader :scope, :user, :config

      # @param scope [ActiveRecord::Relation] The initial scope to be filtered.
      # @param user [User] The current user, for permission-sensitive filters.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      def self.call(scope:, user:, config:)
        new(scope: scope, user: user, config: config).call
      end

      def initialize(scope:, user:, config:)
        @scope = scope
        @user = user
        @config = config
      end

      # Applies each filter class from the configuration to the scope.
      #
      # @return [ActiveRecord::Relation] The filtered scope.
      def call
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
