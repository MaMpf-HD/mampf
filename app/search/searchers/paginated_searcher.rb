module Search
  module Searchers
    # This searcher takes a configured search, executes it, and then paginates
    # the results using Pagy without any direct dependency on the controller.
    class PaginatedSearcher
      # @param model_class [Class] The ActiveRecord model to be searched.
      # @param user [User] The current user performing the search.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      # @param default_per_page [Integer] The default number of items per page.
      # @return [SearchResult] An object containing the paginated results and total count.
      def self.search(model_class:, user:, config:, default_per_page: 10)
        search_results = ModelSearcher.search(
          model_class: model_class,
          user: user,
          config: config
        )

        # Use a subquery to get the correct count
        correct_count = model_class.from(search_results, :subquery_for_count).count

        # 2. Determine pagination settings.
        items_per_page = if config.params[:all]
          search_results.count
        else
          config.params[:per] || default_per_page
        end

        # 3. Instantiate a Pagy object directly. This is the core of the new
        #    decoupled approach. We provide it with the total count, the items
        #    per page, and the current page from the search parameters.
        pagy = Pagy.new(count: correct_count,
                        items: items_per_page,
                        limit: items_per_page,
                        page: config.params[:page])

        # 4. Apply the pagination to the scope using the offset and limit
        #    from the Pagy object.
        paginated_results = search_results.offset(pagy.offset).limit(pagy.vars[:items])

        # 5. Return the pagy object and the now-paginated results.
        SearchResult.new(
          pagy: pagy,
          results: paginated_results
        )
      end
    end
  end
end
