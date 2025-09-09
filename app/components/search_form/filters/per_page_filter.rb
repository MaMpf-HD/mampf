module SearchForm
  module Filters
    # Renders a select field for controlling pagination (items per page).
    # This component uses composition to build a select field that allows for easy
    # configuration of the available page size options and a default value.
    class PerPageFilter < ViewComponent::Base
      attr_accessor :form_state

      # Initializes the PerPageFilter.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param per_options [Array<Array>] An array of [text, value] pairs for the
      #   select options. Defaults to `[[10, 10], [20, 20], [50, 50]]`.
      # @param default [Object] The value that should be pre-selected in the
      #   dropdown. Defaults to `10`.
      # @param options [Hash] Additional options passed to the select field.
      def initialize(form_state:, per_options: [[10, 10], [20, 20], [50, 50]], default: 10,
                     **options)
        super()
        @form_state = form_state
        @per_options = per_options
        @default = default
        @options = options
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          @select_field = Fields::SelectField.new(
            name: :per,
            label: I18n.t("basics.hits_per_page"),
            collection: @per_options,
            selected: @default,
            form_state: form_state,
            **@options
          ).with_form(form)
        end
    end
  end
end
