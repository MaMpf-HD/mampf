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
