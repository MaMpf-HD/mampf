# This service class orchestrates the process of building a complex, filterable,
# and sortable database query for a given model. It uses a set of filter
# classes to apply various conditions and then ensures the results are unique
# and correctly ordered.
class ModelSearch
  attr_reader :model_class, :params, :filter_classes, :user, :fulltext_param

  # Initializes the search service.
  #
  # @param model_class [Class] The ActiveRecord model class to be searched (e.g., Course).
  # @param params [Hash] The search parameters from the controller.
  # @param user [User] The current user, for permission-sensitive filters.
  # @param filter_classes [Array<Class>] An array of filter classes to be applied.
  # @param fulltext_param [Symbol, nil] The key in `params` that contains the
  # full-text search query.

  def initialize(model_class, params, filter_classes, user:, fulltext_param: nil)
    @model_class = model_class
    @params = params.to_h.with_indifferent_access
    @filter_classes = filter_classes
    @user = user
    @fulltext_param = fulltext_param
  end

  # Executes the search by applying filters and ordering.
  #
  # @return [ActiveRecord::Relation] The resulting query object.
  def call
    scope = model_class.all

    # Apply all registered filters to the scope.
    scope = FilterApplier.call(scope: scope, filter_classes: filter_classes,
                               params: params, user: user,
                               fulltext_param: fulltext_param)

    # Ensure the results are unique, as joins can create duplicates.
    scope = scope.distinct

    # Apply the final ordering to the result set.
    SearchOrderer.call(scope: scope, model_class: model_class,
                       params: params, fulltext_param: fulltext_param)
  end
end
