# Filters a scope of media to only include records that are visible to the
# current user.
#
# This filter delegates the complex visibility logic to the
# `User#filter_visible_media` method, which encapsulates all rules related
# to subscriptions, editing rights, and media release status.
module Search
  module Filters
    class MediumVisibilityFilter < BaseFilter
      def call
        # This filter applies the user-specific visibility rules.
        user.filter_visible_media(scope)
      end
    end
  end
end
