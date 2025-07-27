# This service is responsible for applying the correct ordering to a search
# result scope. It prioritizes ordering by full-text search rank if a search
# term is present. Otherwise, it falls back to the model's defined default
# search order. It also ensures that any columns required for ordering are
# included in the SELECT statement to prevent database errors when using DISTINCT.
class SearchOrderer
  attr_reader :scope, :model_class, :params, :fulltext_param

  # Entry point for the service.
  #
  # @param scope [ActiveRecord::Relation] The scope to be ordered.
  # @param model_class [Class] The ActiveRecord model class being searched.
  # @param params [Hash] The search parameters.
  # @param fulltext_param [Symbol, nil] The key for the full-text search parameter.
  # @return [ActiveRecord::Relation] The ordered scope.
  def self.call(...)
    new(...).call
  end

  def initialize(scope:, model_class:, params:, fulltext_param:)
    @scope = scope
    @model_class = model_class
    @params = params.to_h.with_indifferent_access
    @fulltext_param = fulltext_param
  end

  # Applies the ordering logic.
  def call
    return scope if fulltext_search? || !orderable?

    apply_default_order
  end

  private

    # Checks if a full-text search is being performed.
    def fulltext_search?
      fulltext_param && params[fulltext_param].present?
    end

    # Checks if the model has a valid default search order defined.
    def orderable?
      model_class.respond_to?(:default_search_order) &&
        model_class.default_search_order.present?
    end

    # Memoizes the default order expression from the model.
    def order_expression
      @order_expression ||= model_class.default_search_order
    end

    # Adds any necessary `left_outer_joins` that are required for the default
    # ordering of the model.
    def add_required_joins(current_scope)
      return current_scope unless model_class.respond_to?(:default_search_order_joins)

      current_scope.left_outer_joins(model_class.default_search_order_joins)
    end

    # Applies the default order and modifies the SELECT list to include
    # the ordering columns.
    def apply_default_order
      # The order expression string might contain ASC/DESC, which is invalid
      # in a SELECT list. We need to extract just the column names for the SELECT.
      select_columns_sql = order_expression.to_s.gsub(/\s+(ASC|DESC)\b/i, "")
      select_expression = Arel.sql(select_columns_sql)

      # First, add the necessary joins to the scope.
      scope_with_joins = add_required_joins(scope)

      # Always include the order expression in the SELECT list to prevent errors
      # when .distinct is used.
      scope_with_joins.select(model_class.arel_table[Arel.star], select_expression)
                      .order(order_expression)
    end
end
