module Filters
  class MediumVisibilityFilter < BaseFilter
    def call
      # This filter applies the user-specific visibility rules.
      user.filter_visible_media(scope)
    end
  end
end
