# This service object encapsulates the logic for performing a search via
# ModelSearcher, counting the results, and preparing a paginated collection.
module Search
  module Searchers
    class PaginatedSearcher
      # A simple struct to return multiple values from the call method.
      SearchResult = Struct.new(:results, :total_count, keyword_init: true)
      # A struct to bundle configuration options for the search.
      SearchConfig = Struct.new(:search_params, :pagination_params, :default_per_page,
                                :all, :orderer_class, keyword_init: true) do
        # Override initialize to set the default for the 'all' flag to false.
        def initialize(*args)
          super
          self.all = false if all.nil?
        end
      end

      def self.call(...)
        new(...).call
      end

      # @param model_class [Class] The ActiveRecord model to search (e.g., Tag).
      # @param filter_classes [Array<Class>] The specific filter classes to apply.
      # @param user [User] The current user for authorization.
      # @param config [SearchConfig] A struct containing the search/pagination parameters.
      def initialize(model_class:, filter_classes:, user:, config:)
        @model_class = model_class
        @filter_classes = filter_classes
        @user = user
        @config = config
      end

      def call
        search_results = ModelSearcher.new(@model_class, @config.search_params,
                                           @filter_classes,
                                           user: @user,
                                           orderer_class: @config.orderer_class).call

        total_count = calculate_total_count(search_results)

        paginated_results = paginate(search_results, total_count)

        SearchResult.new(results: paginated_results, total_count: total_count)
      end

      private

        def calculate_total_count(scope)
          if scope.group_values.any?
            @model_class.from(scope, :subquery).count
          else
            scope.select(:id).count
          end
        end

        def paginate(scope, total_count)
          # Always convert to an array first for Kaminari.paginate_array
          results_array = scope.to_a
          paginatable_array = Kaminari.paginate_array(results_array, total_count: total_count)

          if @config.all
            # If 'all' is requested, set 'per' to the total count to show all items on one page.
            # We still call .page(1) to ensure it returns a Kaminari object for the view.
            # Use [total_count, 1].max to avoid per(0) if the result set is empty.
            paginatable_array.page(1).per([total_count, 1].max)
          else
            per_page = @config.pagination_params[:per] || @config.default_per_page || 10
            paginatable_array.page(@config.pagination_params[:page]).per(per_page)
          end
        end
    end
  end
end
