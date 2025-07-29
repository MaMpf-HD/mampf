module Filters
  class ProperFilter < BaseFilter
    def call
      scope.proper
    end
  end
end
