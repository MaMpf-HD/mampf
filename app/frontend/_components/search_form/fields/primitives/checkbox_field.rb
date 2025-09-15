module SearchForm
  module Fields
    module Primitives
      # Renders a single checkbox control within the standard field layout.
      #
      # This component provides a styled checkbox input with optional Stimulus.js
      # integration for dynamic behavior like toggling other form elements or
      # controlling radio button groups. It supports both simple toggle actions
      # and complex radio group management.
      #
      # @example Basic checkbox
      #   CheckboxField.new(
      #     name: :accept_terms,
      #     label: "I accept the terms",
      #     form_state: form_state
      #   )
      #
      # @example Checkbox with toggle behavior
      #   CheckboxField.new(
      #     name: :all_items,
      #     label: "All items",
      #     form_state: form_state,
      #     stimulus: { toggle: true }
      #   )
      class CheckboxField < ViewComponent::Base
        include Fields::Mixins::PrimitiveFieldMixin
        attr_reader :checked, :stimulus_config, :field_data

        # Initializes a new CheckboxField component.
        #
        # @param name [Symbol] The field name for form binding and ID generation
        # @param label [String] The human-readable label text
        # @param form_state [FormState] The form state object for context
        # @param checked [Boolean] Whether the checkbox should be initially checked
        # @param stimulus [Hash] Stimulus.js configuration for dynamic behavior
        # @param options [Hash] Additional HTML attributes and configuration
        # rubocop:disable Metrics/ParameterLists
        def initialize(name:, label:, form_state:, checked: false, stimulus: {}, **)
          super()
          @checked = checked
          @stimulus_config = stimulus

          initialize_field_data(
            name: name,
            label: label,
            form_state: form_state,
            default_classes: [], # Checkboxes don't use field-level CSS classes
            **
          )
        end
        # rubocop:enable Metrics/ParameterLists

        delegate :html, to: :field_data

        # Builds the data attributes hash for the checkbox input.
        # Combines custom data attributes with Stimulus.js controller attributes
        # based on the stimulus configuration.
        #
        # @return [Hash] The complete data attributes hash
        def data_attributes
          data = options[:data] || {}
          add_toggle_attributes(data)
          add_radio_group_toggle_attributes(data)
          data
        end

        # Prepares the complete HTML attributes hash for the checkbox input element.
        # Includes Bootstrap styling, accessibility attributes, and Stimulus data attributes.
        #
        # @return [Hash] The complete HTML attributes for the checkbox input
        def checkbox_html_options
          {
            class: "form-check-input",
            checked: checked,
            id: html.element_id,
            "aria-describedby": (html.help_text_id if show_help_text?),
            data: (data_attributes if data_attributes.any?)
          }.compact.merge(options.except(:container_class, :data))
        end

        private

          # Adds Stimulus data attributes for basic toggle functionality.
          # When enabled, the checkbox can toggle other form elements.
          #
          # @param data [Hash] The data attributes hash to modify
          # @return [void]
          def add_toggle_attributes(data)
            return unless stimulus_config[:toggle]

            data[:search_form_target] = "allToggle"
            data[:action] = "change->search-form#toggleFromCheckbox"
          end

          # Adds Stimulus data attributes for radio group toggle functionality.
          # When enabled, the checkbox can control the state of radio button groups.
          #
          # @param data [Hash] The data attributes hash to modify
          # @return [void]
          def add_radio_group_toggle_attributes(data)
            return unless stimulus_config[:toggle_radio_group]

            data[:action] = build_radio_toggle_action(data[:action])
            data[:toggle_radio_group] = stimulus_config[:toggle_radio_group]
            return unless stimulus_config[:default_radio_value]

            data[:default_radio_value] =
              stimulus_config[:default_radio_value]
          end

          # Builds the combined Stimulus action string for radio group toggles.
          # Safely appends radio toggle action to any existing actions.
          #
          # @param existing_action [String, nil] Any existing Stimulus action
          # @return [String] The combined action string
          def build_radio_toggle_action(existing_action)
            radio_action = "change->search-form#toggleRadioGroup"
            existing_action.present? ? "#{existing_action} #{radio_action}" : radio_action
          end
      end
    end
  end
end
