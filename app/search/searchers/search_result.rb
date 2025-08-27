module Search
  module Searchers
    # Provides a consistent data object for the results of a paginated search.
    class SearchResult
      attr_reader :results, :total_count

      # Initializes a new SearchResult object.
      #
      # @param results [Kaminari::PaginatableArray] The paginated results.
      # @param total_count [Integer] The total number of unpaginated results.
      def initialize(results:, total_count:)
        @results = results
        @total_count = total_count
      end
    end
  end
end
