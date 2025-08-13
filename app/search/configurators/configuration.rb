module Search
  module Configurators
    # Provides a consistent data object for search configurations.
    # It holds the array of filter classes to be applied, the processed search
    # parameters, and the class responsible for ordering the results.
    class Configuration
      attr_reader :filters, :params, :orderer_class

      # Initializes a new Configuration object.
      #
      # @param filters [Array<Class>] An array of filter classes to be applied.
      # @param params [Hash] A hash of processed and sanitized search parameters.
      # @param orderer_class [Class, nil] An optional class for ordering results.
      #   If nil, the search will fall back to the default orderer.
      def initialize(filters:, params:, orderer_class: nil)
        @filters = filters
        @params = params
        @orderer_class = orderer_class
      end
    end
  end
end
