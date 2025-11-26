module Search
  module Searchers
    # Acts as the bridge between the ModelSearcher and the Pagy gem.
    # It takes the full, unpaginated ActiveRecord::Relation from the ModelSearcher,
    # calculates the total number of results, and then applies pagination logic.
    #
    # It handles the complexity of getting a correct count from a potentially
    # complex query (e.g., one with DISTINCT or GROUP BY) by using a subquery.
    # It then manually initializes a Pagy object and applies the correct OFFSET
    # and LIMIT clauses to the relation before returning a SearchResult.
    class PaginatedSearcher
      # Executes the search and paginates the results.
      #
      # @param model_class [Class] The ActiveRecord model to be searched.
      # @param user [User] The current user performing the search.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      # @param default_per_page [Integer] The default number of items per page.
      # @return [SearchResult] An object containing the Pagy object and the
      #   paginated ActiveRecord::Relation for the current page.
      def self.search(model_class:, user:, config:, default_per_page: 10)
        search_results = ModelSearcher.search(
          model_class: model_class,
          user: user,
          config: config
        )

        # To get an accurate count from a query that might contain DISTINCT or
        # GROUP BY clauses, we wrap the original query in a subquery and
        # count the results of that.
        correct_count = model_class.from(search_results, :subquery_for_count).count

        items_per_page = if config.params[:all]
          # Use a minimum of 1 to avoid Pagy errors if the count is 0.
          [correct_count, 1].max
        else
          config.params[:per] || default_per_page
        end

        pagy = Pagy.new(count: correct_count,
                        limit: items_per_page,
                        page: config.params[:page])

        paginated_results = search_results.offset(pagy.offset).limit(pagy.limit)

        SearchResult.new(
          pagy: pagy,
          results: paginated_results
        )
      end
    end
  end
end
