module SearchForm
  module Fields
    module Primitives
      # Renders a single radio button control within the standard field layout.
      #
      # Radio buttons are typically used in groups where only one option can be selected.
      # This component handles individual radio button rendering with support for custom
      # container styling, Stimulus.js integration, and accessibility features.
      #
      # Unlike other field components, radio buttons require both a name (for grouping)
      # and a value (for the individual option), and can have custom container classes
      # for inline vs. block layouts.
      #
      # @example Basic radio button
      #   RadioButtonField.new(
      #     name: :size,
      #     value: "large",
      #     label: "Large",
      #     form_state: form_state
      #   )
      #
      # @example Inline radio button with stimulus
      #   RadioButtonField.new(
      #     name: :filter_type,
      #     value: "advanced",
      #     label: "Advanced Filter",
      #     form_state: form_state,
      #     checked: true,
      #     inline: true,
      #     stimulus: { radio_toggle: true }
      #   )
      class RadioButtonField < ViewComponent::Base
        include FieldMixins

        attr_reader :value, :checked, :custom_container_class, :field_data

        # Initializes a new RadioButtonField component.
        #
        # @param name [Symbol] The field name for grouping radio buttons
        # @param value [String, Symbol] The value for this specific radio button option
        # @param label [String] The human-readable label text for this option
        # @param form_state [FormState] The form state object for context
        # @param checked [Boolean] Whether this radio button should be initially selected
        # @param help_text [String, nil] Optional help text for accessibility
        # @param container_class [String, nil] Custom CSS class for the container div
        # @param options [Hash] Additional HTML attributes and configuration including:
        #   - inline: Whether to use inline layout (affects default container class)
        #   - disabled: Whether this radio button is disabled
        #   - stimulus: Hash of Stimulus.js configuration options
        #   - data: Hash of additional data attributes
        def initialize(name:, value:, label:, form_state:, checked: false, help_text: nil,
                       container_class: nil, **)
          super()
          @value = value
          @checked = checked
          @custom_container_class = container_class

          initialize_field_data(
            name: name,
            label: label,
            form_state: form_state,
            help_text: help_text,
            default_classes: [], # Radio buttons don't use field-level CSS classes
            **
          )
        end

        # Additional delegations specific to radio buttons
        delegate :html, to: :field_data

        # Determines the CSS class for the container div.
        # Uses custom class if provided, otherwise defaults based on inline option.
        #
        # @return [String] The CSS class string for the container
        def container_class
          return custom_container_class if custom_container_class

          options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
        end

        # Generates the unique HTML ID for this specific radio button.
        # Radio buttons need value-specific IDs to distinguish between options.
        #
        # @return [String] The complete element ID including form scope and value
        def element_id
          form_state.element_id_for(name, value: value)
        end

        # Generates the label's `for` attribute value for this radio button.
        #
        # @return [String] The ID that the label should reference
        def label_for
          form_state.label_for(name, value: value)
        end

        # Generates the help text element ID for ARIA accessibility.
        #
        # @return [String] The help text element ID
        def help_text_id
          "#{element_id}_help"
        end

        # Builds the data attributes hash for the radio button input.
        # Combines custom data attributes with Stimulus.js controller attributes
        # based on the stimulus configuration.
        #
        # @return [Hash] The complete data attributes hash
        def data_attributes
          data = options[:data] || {}
          add_radio_toggle_attributes(data)
          add_controls_select_attributes(data)
          data
        end

        # Prepares the complete HTML attributes hash for the radio button input element.
        # Includes Bootstrap styling, checked state, accessibility attributes, and Stimulus data.
        #
        # @return [Hash] The complete HTML attributes for the radio button input
        def radio_button_html_options
          {
            class: "form-check-input",
            checked: checked,
            id: element_id,
            "aria-describedby": (help_text_id if show_help_text?),
            disabled: options[:disabled],
            data: (data_attributes if data_attributes.any?)
          }.compact.merge(options.except(:inline, :container_class, :stimulus))
        end

        private

          # Adds Stimulus data attributes for radio button toggle functionality.
          # When enabled, changing this radio button can trigger other form changes.
          #
          # @param data [Hash] The data attributes hash to modify
          # @return [void]
          def add_radio_toggle_attributes(data)
            return unless stimulus_config[:radio_toggle]

            data[:search_form_target] = "radioToggle"
            data[:action] = "change->search-form#toggleFromRadio"
          end

          # Adds Stimulus data attributes for select element control.
          # When enabled, this radio button can control the state of select dropdowns.
          #
          # @param data [Hash] The data attributes hash to modify
          # @return [void]
          def add_controls_select_attributes(data)
            return unless stimulus_config[:controls_select]

            data[:controls_select] = stimulus_config[:controls_select].to_s
          end

          # Retrieves the Stimulus.js configuration from the options.
          #
          # @return [Hash] The stimulus configuration hash
          def stimulus_config
            options[:stimulus] || {}
          end
      end
    end
  end
end
