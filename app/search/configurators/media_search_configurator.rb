# This class is responsible for configuring a search for the Medium model.
# It acts as a bridge between the raw search parameters from the controller and
# the generic ModelSearch service.
#
# Its primary responsibilities are:
# 1.  Assembling the correct set of filter classes to be applied. This includes
#     conditionally selecting a visibility filter (MediumAccessFilter for editors,
#     MediumVisibilityFilter for regular users) based on user permissions.
# 2.  Pre-processing the search parameters to normalize them before they are
#     passed to the filters. For example, it sets default media types when
#     searching from the start page and removes parameters that are not
#     relevant for the current user's role.
#
# The result is a Configuration object containing the finalized list of filters
# and processed parameters, ready to be executed by the ModelSearch service.
module Search
  module Configurators
    class MediaSearchConfigurator < BaseSearchConfigurator
      def call
        Configuration.new(
          filters: filters,
          params: process_params
        )
      end

      private

        def filters
          build_filters + visibility_filters
        end

        def build_filters
          [
            Filters::ProperFilter,
            Filters::TypeFilter,
            Filters::TeachableFilter,
            Filters::TagFilter,
            Filters::EditorFilter,
            Filters::AnswerCountFilter,
            Filters::LectureScopeFilter,
            Filters::FulltextFilter
          ]
        end

        def visibility_filters
          if user.active_teachable_editor?
            [Filters::MediumAccessFilter]
          else
            [Filters::MediumVisibilityFilter]
          end
        end

        def process_params
          processed = search_params.deep_dup

          if user.active_teachable_editor?
            process_for_editor(processed)
          else
            process_for_generic_user(processed)
          end

          processed
        end

        # Applies strict security restrictions for a generic user.
        def process_for_generic_user(processed)
          restrict_to_generic_types(processed)
          processed.delete(:access)
        end

        # Applies restrictions for an editor, but only on the start page.
        def process_for_editor(processed)
          return unless processed[:from] == "start"

          restrict_to_generic_types(processed)
        end

        # This helper method contains the shared logic for restricting a search
        # to only the generic media types.
        def restrict_to_generic_types(processed)
          if processed[:types].present?
            processed[:types] &= Medium.generic_sorts
          else
            processed[:types] = Medium.generic_sorts
          end
          # Force 'all_types' to off to ensure the TypeFilter is always applied.
          processed[:all_types] = "0"
        end
    end
  end
end
