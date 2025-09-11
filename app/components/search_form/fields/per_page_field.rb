module SearchForm
  module Fields
    # Renders a select field for controlling pagination (items per page).
    # This component provides predefined options for page sizes with a configurable
    # default selection. It's designed to give users control over how many search
    # results are displayed per page.
    #
    # The field offers common pagination options (10, 20, 50 items per page) by
    # default, but can be customized with different options and default values
    # to suit specific use cases.
    #
    # @example Basic per-page field with defaults
    #   PerPageField.new(form_state: form_state)
    #
    # @example Custom per-page options and default
    #   PerPageField.new(
    #     form_state: form_state,
    #     per_options: [[5, 5], [15, 15], [25, 25]],
    #     default: 15
    #   )
    class PerPageField < ViewComponent::Base
      include Mixin::FieldSetupMixin

      attr_reader :per_options, :default, :options

      # Initializes a new PerPageField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param per_options [Array<Array>] Array of [text, value] pairs for the select options.
      #   Defaults to [[10, 10], [20, 20], [50, 50]]
      # @param default [Object] The value that should be pre-selected in the dropdown.
      #   Defaults to 10
      # @param options [Hash] Additional options passed to the underlying select field
      def initialize(form_state:, per_options: [[10, 10], [20, 20], [50, 50]], default: 10,
                     **options)
        super()
        @form_state = form_state
        @per_options = per_options
        @default = default
        @options = options
      end

      private

        def setup_fields
          @select_field = create_select_field(
            name: :per,
            label: I18n.t("basics.hits_per_page"),
            collection: per_options,
            selected: default,
            **options
          )
        end
    end
  end
end
