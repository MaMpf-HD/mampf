# This class is responsible for configuring a search for the Tag model.
# It acts as a bridge between the controller's search parameters and the
# generic ModelSearch service.
#
# Its primary role is to define the specific, static set of filter classes
# that are applied when searching for tags. It returns a Configuration
# object that the ModelSearch service can then execute.
module Search
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
            Filters::CourseFilter,
            Filters::FulltextFilter
          ]
        end
    end
  end
end
