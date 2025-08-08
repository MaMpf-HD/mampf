# This service is responsible for applying a series of filter classes to an
# ActiveRecord scope. It iterates through the provided filter classes,
# initializes each with the current scope and parameters, and then calls it.
# This pattern allows for modular and reusable filtering logic.
module Search
  module Filters
    class FilterApplier
      attr_reader :scope, :filter_classes, :params, :user

      # Applies the filters to the scope.
      #
      # @param scope [ActiveRecord::Relation] The initial scope to be filtered.
      # @param filter_classes [Array<Class>] An array of filter classes to apply.
      # @param params [Hash] The search parameters.
      # @param user [User] The current user.
      # @return [ActiveRecord::Relation] The filtered scope.
      def self.call(...)
        new(...).call
      end

      def initialize(scope:, filter_classes:, params:, user:)
        @scope = scope
        @filter_classes = filter_classes
        @params = params.to_h.with_indifferent_access
        @user = user
      end

      def call
        filter_classes.reduce(scope) do |current_scope, filter_class|
          filter_class.new(scope: current_scope, params: params, user: user).call
        end
      end
    end
  end
end
