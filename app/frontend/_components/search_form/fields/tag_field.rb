module SearchForm
  module Fields
    # Renders a complex tag filtering component with multi-select dropdown,
    # "All" toggle checkbox, and radio buttons for tag operator selection.
    # This component provides sophisticated tag-based filtering with both
    # selection control and logical operator choice.
    #
    # The field combines three interactive elements:
    # - Multi-select dropdown for tag selection (with AJAX loading)
    # - "All" checkbox that toggles all tags and controls radio button state
    # - OR/AND radio buttons to specify how multiple tags should be matched
    #
    # The component uses advanced Stimulus integration where the "All" checkbox
    # can toggle the radio button group and set default values, providing
    # a smooth user experience for complex filtering scenarios.
    #
    # @example Basic tag field
    #   TagField.new(form_state: form_state)
    #
    # @example Tag field with additional options
    #   TagField.new(
    #     form_state: form_state,
    #     data: { custom_attribute: "value" }
    #   )
    class TagField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new TagField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying multi-select field
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          setup_multi_select_field
          setup_checkbox_group
          setup_radio_group
        end

        def setup_multi_select_field
          @multi_select_field = create_multi_select_field(
            name: :tag_ids,
            label: I18n.t("basics.tags"),
            help_text: I18n.t("search.fields.helpdesks.tag_field"),
            collection: [],
            data: ajax_data_attributes,
            **options
          )
        end

        def setup_checkbox_group
          @all_checkbox = create_all_checkbox(
            for_field_name: :tag_ids,
            stimulus: {
              toggle: true,
              toggle_radio_group: "tag_operator",
              default_radio_value: "or"
            }
          )

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def setup_radio_group
          @or_radio_button = create_radio_button_field(
            name: :tag_operator,
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          )

          @and_radio_button = create_radio_button_field(
            name: :tag_operator,
            value: "and",
            label: I18n.t("basics.AND"),
            checked: false,
            disabled: true,
            inline: true,
            container_class: "form-check form-check-inline",
            stimulus: { radio_toggle: true, controls_select: false }
          )

          @radio_group_wrapper = Fields::Utilities::RadioGroupWrapper.new(
            name: :tag_operator,
            parent_field: @multi_select_field,
            radio_buttons: [@or_radio_button, @and_radio_button]
          )
        end

        def ajax_data_attributes
          {
            filled: false,
            ajax: true,
            model: "tag",
            locale: I18n.locale,
            placeholder: I18n.t("basics.select"),
            no_results: I18n.t("basics.no_results")
          }
        end
    end
  end
end
