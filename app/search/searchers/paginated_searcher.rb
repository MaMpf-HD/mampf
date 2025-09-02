module Search
  module Searchers
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

        total_count = calculate_total_count(search_results, model_class)
        paginated_results = paginate(search_results, total_count, config.params, default_per_page)

        Search::Searchers::SearchResult.new(
          results: paginated_results,
          total_count: total_count
        )
      end

      class << self
        private

          def calculate_total_count(scope, model_class)
            if scope.is_a?(Array)
              scope.size
            elsif scope.group_values.any?
              model_class.from(scope, :subquery).count
            else
              scope.select(:id).count
            end
          end

          def paginate(scope, total_count, params, default_per_page)
            results_array = scope.to_a
            paginatable_array = Kaminari.paginate_array(results_array, total_count: total_count)
            pagination_params = params.slice(:page, :per)
            if params[:all]
              # If 'all' is requested, set 'per' to the total count to show all items on one page.
              # We still call .page(1) to ensure it returns a Kaminari object for the view.
              # Use [total_count, 1].max to avoid per(0) if the result set is empty.
              paginatable_array.page(1).per([total_count, 1].max)
            else
              per_page = pagination_params[:per] || default_per_page || 10
              paginatable_array.page(pagination_params[:page]).per(per_page)
            end
          end
      end
    end
  end
end
