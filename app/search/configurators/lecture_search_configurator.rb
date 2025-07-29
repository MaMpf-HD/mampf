module Configurators
  class LectureSearchConfigurator < BaseSearchConfigurator
    def call
      Configuration.new(
        filters: filters,
        params: search_params
      )
    end

    private

      def filters
        [
          ::Filters::LectureTypeFilter,
          ::Filters::TermFilter,
          ::Filters::ProgramFilter,
          ::Filters::TeacherFilter,
          ::Filters::LectureVisibilityFilter,
          ::Filters::FulltextFilter
        ]
      end
  end
end
