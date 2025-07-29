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
          ::Filters::ProperFilter,
          ::Filters::TypeFilter,
          ::Filters::TeachableFilter,
          ::Filters::TagFilter,
          ::Filters::EditorFilter,
          ::Filters::AnswerCountFilter,
          ::Filters::LectureScopeFilter,
          ::Filters::FulltextFilter
        ]
      end

      def visibility_filters
        if user.active_teachable_editor?
          [::Filters::MediumAccessFilter]
        else
          [::Filters::MediumVisibilityFilter]
        end
      end

      def process_params
        processed = search_params.deep_dup

        # Remove the :access parameter if the user is not an editor, as the
        # MediumVisibilityFilter does not use it.
        processed.delete(:access) unless user.active_teachable_editor?

        # If "all types" is selected from the start page search, we default to
        # searching within all generic media types.
        if processed[:all_types] == "1" && processed[:from] == "start"
          processed[:types] = Medium.generic_sorts
        end

        processed
      end
  end
end
