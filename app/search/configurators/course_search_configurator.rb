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
