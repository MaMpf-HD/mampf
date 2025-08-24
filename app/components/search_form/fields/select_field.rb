# frozen_string_literal: true

module SearchForm
  module Fields
    # Select field component for dropdown selection
    #
    # This field type renders a standard HTML select dropdown with options.
    # It's used for single-value selection from a predefined set of options,
    # such as course selection, term filtering, or status selection.
    #
    # @param collection [Array] Array of options for the select dropdown
    #   Can be simple arrays, arrays of arrays, or ActiveRecord collections
    #
    # @example Basic select field
    #   add_select_field(
    #     name: :term_id,
    #     label: "Term",
    #     collection: terms_for_select,
    #     prompt: "Select a term"
    #   )
    #
    # @example Select with custom collection
    #   add_select_field(
    #     name: :status,
    #     label: "Status",
    #     collection: [["Active", "active"], ["Inactive", "inactive"]]
    #   )
    class SelectField < Field
      attr_reader :collection

      def initialize(name:, label:, collection:, **options)
        @collection = collection

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)
      end

      # Options hash for the select tag (the second parameter to form.select)
      delegate :select_tag_options, to: :html

      def default_field_classes
        ["form-select"] # Bootstrap form-select class
      end
    end
  end
end
