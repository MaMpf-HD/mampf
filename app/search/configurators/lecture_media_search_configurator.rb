# This class is responsible for configuring a search for media within the
# context of a specific lecture's index page.
#
# It defines the specific set of filters needed to replicate the legacy
# search logic from the MediaController, including initial scoping,
# visibility rules, and the inclusion of imported media.
module Search
  module Configurators
    class LectureMediaSearchConfigurator < BaseSearchConfigurator
      def call
        Configuration.new(
          filters: filters,
          params: search_params
        )
      end

      private

        def filters
          [
            Filters::LectureMediaScopeFilter,
            Filters::ImportedMediaFilter,
            Filters::LectureMediaVisibilityFilter,
            Filters::MediumVisibilityFilter
          ]
        end
    end
  end
end
