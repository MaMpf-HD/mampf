# Abstract base class for all search sorters.
#
# It establishes a common interface and initialization logic that all concrete
# sorter classes should inherit from. Each sorter is expected to implement a
# `sort` method that returns a modified, sorted scope.
module Search
  module Sorters
    class BaseSorter
      attr_reader :scope, :model_class, :search_params

      # Entry point for the service.
      #
      # @param scope [ActiveRecord::Relation] The scope to be sorted.
      # @param model_class [Class] The ActiveRecord model class being searched.
      # @param search_params [Hash] The search parameters.
      # @param keyset_mode [Boolean] If true, skip applying default order
      #   (will be applied by model's keyset_order_setup instead)
      # @return [ActiveRecord::Relation] The sorted scope.
      def self.sort(scope:, model_class:, search_params:, keyset_mode: false)
        # Get the ordered scope from the specific sorter subclass.
        sorted_scope = new(scope: scope, model_class: model_class,
                           search_params: search_params,
                           keyset_mode: keyset_mode).sort

        return sorted_scope.reverse_order if search_params[:reverse]

        sorted_scope
      end

      def initialize(scope:, model_class:, search_params:, keyset_mode: false)
        @scope = scope
        @model_class = model_class
        @search_params = search_params.to_h.with_indifferent_access
        @keyset_mode = keyset_mode
      end

      # Subclasses must implement this method to apply sorting logic.
      def sort
        raise(NotImplementedError, "#{self.class} has not implemented method '#{__method__}'")
      end

      protected

        def keyset_mode?
          @keyset_mode
        end
    end
  end
end
