module Filters
  class BaseFilter
    attr_reader :scope, :params, :user, :fulltext_param

    def initialize(scope, params, user:, fulltext_param: nil)
      @scope = scope
      @params = params.to_h.with_indifferent_access
      @user = user
      @fulltext_param = fulltext_param
    end

    def call
      raise(NotImplementedError, "Subclasses must implement #call")
    end
  end
end
