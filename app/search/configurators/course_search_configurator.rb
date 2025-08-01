# Defines the search configuration for the Course model.
#
# This class specifies the set of filters that are applied when searching for
# courses.
module Configurators
  class CourseSearchConfigurator < BaseSearchConfigurator
    def call
      Configuration.new(
        filters: filters,
        params: search_params
      )
    end

    private

      def filters
        [
          ::Filters::EditorFilter,
          ::Filters::ProgramFilter,
          ::Filters::TermIndependenceFilter,
          ::Filters::FulltextFilter
        ]
      end
  end
end
