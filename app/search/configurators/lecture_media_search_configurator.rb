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
        # and normalization for pagination and ordering.
        def processed_params
          processed = search_params.deep_dup

          # If an explicit 'per' parameter is provided in the URL, it should
          # always override a stale 'all' cookie from a previous request.
          cookies[:all] = "false" if processed[:per].present?

          # Handle 'all' parameter, falling back to cookie value.
          show_all = (processed[:all] == "true") || (cookies[:all] == "true")
          cookies[:all] = show_all.to_s
          processed[:all] = show_all

          # If showing all, clear the 'per' cookie. Otherwise, sanitize 'per'.
          if show_all
            cookies.delete(:per)
          else
            processed[:per] = sanitized_per_page(processed[:per])
          end

          # Normalize the 'reverse' parameter to a boolean.
          processed[:reverse] = processed[:reverse] == "true"

          processed
        end

        # Extracts and sanitizes the 'per_page' value from params or cookies.
        def sanitized_per_page(per_param)
          allowed_per_values = [3, 4, 8, 12, 24, 48]
          per_page = per_param.to_i

          # If a valid 'per' param is given, use it and store it in the cookie.
          if per_page.in?(allowed_per_values)
            cookies[:per] = per_page
            return per_page
          end

          # Otherwise, try to use a valid value from the cookie.
          cookie_per = cookies[:per].to_i
          return cookie_per if cookie_per.in?(allowed_per_values)

          # Fall back to a default value.
          8
        end
    end
  end
end
