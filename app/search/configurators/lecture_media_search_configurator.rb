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
          params: processed_params,
          sorter_class: Search::Sorters::LectureMediaSorter
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

        # Processes the raw search parameters to handle cookie-based persistence
        # and normalization for pagination and sorting.
        def processed_params
          processed = search_params.deep_dup

          cookies[:all] = "false" if processed[:per].present?

          show_all = (processed[:all] == "true") || (cookies[:all] == "true")
          cookies[:all] = show_all.to_s
          processed[:all] = show_all

          if show_all
            cookies.delete(:per)
          else
            processed[:per] = sanitized_per_page(processed[:per])
          end

          processed[:reverse] = processed[:reverse] == "true"

          processed
        end

        # Extracts and sanitizes the 'per_page' value from params or cookies.
        def sanitized_per_page(per_param)
          allowed_per_values = [3, 4, 8, 12, 24, 48]
          per_page = per_param.to_i

          if per_page.in?(allowed_per_values)
            cookies[:per] = per_page
            return per_page
          end

          cookie_per = cookies[:per].to_i
          return cookie_per if cookie_per.in?(allowed_per_values)

          8
        end
    end
  end
end
