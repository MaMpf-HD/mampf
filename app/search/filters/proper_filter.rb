# Applies the model's `.proper` scope, if it exists, to filter out records
# that should not appear in user-facing search results.
#
# This filter checks if the model responds to the `.proper` scope before
# applying it. This allows it to be safely included in any search
# configuration without causing errors for models that do not implement it.
module Filters
  class ProperFilter < BaseFilter
    def call
      # Only apply the scope if the model defines it.
      scope.respond_to?(:proper) ? scope.proper : scope
    end
  end
end
