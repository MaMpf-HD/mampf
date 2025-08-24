# frozen_string_literal: true

module SearchForm
  module Fields
    # Text field component for single-line text input
    #
    # This field type renders a standard HTML text input with Bootstrap styling.
    # It's commonly used for search terms, names, titles, and other short text
    # values in search forms.
    #
    # @example Basic text field
    #   add_text_field(
    #     name: :search_term,
    #     label: "Search Term",
    #     help_text: "Enter keywords to search"
    #   )
    #
    # @example Text field with placeholder
    #   add_text_field(
    #     name: :title,
    #     label: "Title",
    #     prompt: "Enter lecture title..."
    #   )
    class TextField < Field
      def initialize(name:, label:, **options)
        super

        extract_and_update_field_classes!(options)
      end

      def default_field_classes
        ["form-control"] # Bootstrap form-control class
      end
    end
  end
end
