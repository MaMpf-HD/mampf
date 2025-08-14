# This is the abstract base class for all search sorters.
#
# It establishes a common interface and initialization logic that all concrete
# sorter classes should inherit. Each sorter is initialized with a scope,
# the model class, and the search parameters. It is expected to implement a
# `call` method that returns a modified, sorted scope.
module Search
  module Sorters
    class BaseSorter
      attr_reader :scope, :model_class, :search_params

      # Entry point for the service.
      #
      # @param scope [ActiveRecord::Relation] The scope to be ordered.
      # @param model_class [Class] The ActiveRecord model class being searched.
      # @param search_params [Hash] The search parameters.
      # @return [ActiveRecord::Relation] The ordered scope.
      def self.call(scope:, model_class:, search_params:)
        # Get the ordered scope from the specific sorter subclass.
        sorted_scope = new(scope: scope, model_class: model_class,
                           search_params: search_params).call

        # If the 'reverse' parameter is true, reverse the order of the scope.
        return sorted_scope.reverse_order if search_params[:reverse]

        sorted_scope
      end

      def initialize(scope:, model_class:, search_params:)
        @scope = scope
        @model_class = model_class
        @search_params = search_params.to_h.with_indifferent_access
      end

      # Subclasses must implement this method to apply sorting logic.
      def call
        raise(NotImplementedError, "#{self.class} has not implemented method '#{__method__}'")
      end
    end
  end
end
