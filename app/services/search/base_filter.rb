module Search
  class BaseFilter
    attr_reader :scope, :params, :fulltext_param

    def initialize(scope, params, fulltext_param: nil)
      @scope = scope
      @params = params.to_h.with_indifferent_access
      @fulltext_param = fulltext_param
    end

    def call
      raise(NotImplementedError, "Subclasses must implement #call")
    end
  end
end
