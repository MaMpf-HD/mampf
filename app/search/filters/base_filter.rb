# This is the abstract base class for all search filters.
#
# It defines the common interface and initialization logic that all concrete
# filter classes should inherit. Each filter is initialized with a scope,
# parameters, and a user, and is expected to implement a `call` method
# that returns a modified scope.
module Search
  module Filters
    class BaseFilter
      attr_reader :scope, :params, :user

      # Syntactic sugar to allow calling FilterClass.apply(...) instead of .new(...).call
      def self.apply(scope:, params:, user:)
        new(scope: scope, params: params, user: user).call
      end

      def initialize(scope:, params:, user:)
        @scope = scope
        @params = params.to_h.with_indifferent_access
        @user = user
      end

      def call
        raise(NotImplementedError, "Subclasses must implement #call")
      end

      private

        # Helper to check for the standard "all" and blank ID guard clauses.
        #
        # @param all_param [Symbol] The key for the 'all' flag (e.g., :all_editors).
        # @param ids_param [Symbol] The key for the ID list (e.g., :editor_ids).
        # @return [Boolean] True if the filter should be skipped.
        def skip_filter?(all_param:, ids_param:)
          params[all_param] == "1" || params[ids_param].to_a.compact_blank.empty?
        end
    end
  end
end
