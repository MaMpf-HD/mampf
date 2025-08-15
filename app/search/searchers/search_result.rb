module Search
  module Searchers
    # Provides a consistent data object for the results of a paginated search.
    # It holds the pagy metadata object and the paginated collection of records
    # for the current page.
    class SearchResult
      attr_reader :pagy, :results

      # Initializes a new SearchResult object.
      #
      # @param pagy [Pagy] The Pagy metadata object, containing pagination info.
      # @param results [ActiveRecord::Relation] The paginated collection of results.
      def initialize(pagy:, results:)
        @pagy = pagy
        @results = results
      end
    end
  end
end
