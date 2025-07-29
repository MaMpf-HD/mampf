module Configurators
  class TagSearchConfigurator < BaseSearchConfigurator
    def call
      Configuration.new(
        filters: filters,
        params: search_params
      )
    end

    private

      def filters
        [
          ::Filters::CourseFilter,
          ::Filters::FulltextFilter
        ]
      end
  end
end
