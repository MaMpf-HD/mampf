class ModelSearchService
  attr_reader :model_class, :params, :filter_classes, :fulltext_param

  def initialize(model_class, params, filter_classes, fulltext_param: nil)
    @model_class = model_class
    @params = params
    @filter_classes = filter_classes
    @fulltext_param = fulltext_param
  end

  def call
    scope = model_class.all
    scope = apply_filters(scope)
    apply_ordering(scope)
  end

  private

    def apply_filters(initial_scope)
      filter_classes.reduce(initial_scope) do |current_scope, filter_class|
        filter_class.new(current_scope, params, fulltext_param: @fulltext_param).call
      end
    end

    def apply_ordering(scope)
      # if fulltext is given then pg_search's .with_pg_search_rank already added
      # the order by rank
      return scope if @fulltext_param && params[@fulltext_param].present?

      if model_class.respond_to?(:default_search_order)
        order_expression = model_class.default_search_order
        if order_expression.present?
          return scope.select(model_class.arel_table[Arel.star], order_expression)
                      .order(order_expression)
        end
      end

      # If no other ordering was applied, return the original scope
      scope
    end
end
