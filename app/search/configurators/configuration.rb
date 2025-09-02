module Search
  module Configurators
    # Provides a consistent data object for search configurations.
    # It holds the array of filter classes to be applied, the processed search
    # parameters, and the class responsible for sorting the results.
    class Configuration
      attr_reader :filters, :params, :sorter_class

      # Initializes a new Configuration object.
      #
      # @param filters [Array<Class>] An array of filter classes to be applied.
      # @param params [Hash] A hash of processed and sanitized search parameters.
      # @param sorter_class [Class, nil] An optional class for sorting results.
      #   If nil, the search will fall back to the default sorter.
      def initialize(filters:, params:, sorter_class: nil)
        @filters = filters
        @params = params
        @sorter_class = sorter_class
      end
    end
  end
end
