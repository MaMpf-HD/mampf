# This is the abstract base class for all search filters.
#
# It defines the common interface and initialization logic that all concrete
# filter classes should inherit. Each filter is initialized with a scope,
# parameters, and a user, and is expected to implement a `call` method
# that returns a modified scope.
module Filters
  class BaseFilter
    attr_reader :scope, :params, :user

    def initialize(scope, params, user:)
      @scope = scope
      @params = params.to_h.with_indifferent_access
      @user = user
    end

    def call
      raise(NotImplementedError, "Subclasses must implement #call")
    end
  end
end
