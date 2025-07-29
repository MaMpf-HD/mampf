# This service object encapsulates the logic for performing a search via
# ModelSearch, counting the results, and preparing a paginated collection.
class PaginatedSearcher
  # A simple struct to return multiple values from the call method.
  SearchResult = Struct.new(:results, :total_count, keyword_init: true)
  # A struct to bundle configuration options for the search.
  SearchConfig = Struct.new(:search_params, :pagination_params, :default_per_page,
                            keyword_init: true)

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
    search_results = ::ModelSearch.new(@model_class, @config.search_params,
                                       @filter_classes,
                                       user: @user).call

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
      per_page = @config.search_params[:per] || @config.default_per_page || 10
      Kaminari.paginate_array(scope.to_a, total_count: total_count)
              .page(@config.pagination_params[:page]).per(per_page)
    end
end
