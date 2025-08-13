module Search
  module Searchers
    class PaginatedSearcher
      # This struct holds the results of a paginated search.
      SearchResult = Struct.new(:results, :total_count, keyword_init: true)

      # @param model_class [Class] The ActiveRecord model to be searched.
      # @param user [User] The current user performing the search.
      # @param config [Configurators::Configuration]
      #   The configuration object from the model's configurator.
      # @param default_per_page [Integer] The default number of items per page.
      def self.call(model_class:, user:, config:, default_per_page: 10)
        new(model_class: model_class, user: user, config: config,
            default_per_page: default_per_page).call
      end

      attr_reader :model_class, :user, :config, :default_per_page

      def initialize(model_class:, user:, config:, default_per_page:)
        @model_class = model_class
        @user = user
        @config = config
        @default_per_page = default_per_page
      end

      def call
        # Get the fully filtered and ordered results.
        search_results = ModelSearcher.call(
          model_class: model_class,
          user: user,
          config: config
        )

        # Get the total count before pagination.
        total_count = calculate_total_count(search_results)

        # Paginate the results.
        paginated_results = paginate(search_results, total_count)

        # Return the final results and the total count for the view.
        SearchResult.new(
          results: paginated_results,
          total_count: total_count
        )
      end

      private

        def calculate_total_count(scope)
          if scope.is_a?(Array)
            scope.size
          elsif scope.group_values.any?
            model_class.from(scope, :subquery).count
          else
            scope.select(:id).count
          end
        end

        def paginate(scope, total_count)
          # Always convert to an array first for Kaminari.paginate_array
          results_array = scope.to_a
          paginatable_array = Kaminari.paginate_array(results_array, total_count: total_count)
          pagination_params = config.params.slice(:page, :per)
          if config.params[:all]
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
