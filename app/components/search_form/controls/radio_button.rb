module SearchForm
  module Controls
    # Renders a single radio button and its associated label.
    # This component is designed to be used within a group of radio buttons
    # that share the same `name`. It extends `BaseControl` to add specific logic
    # for handling radio button state and generating Stimulus.js data attributes.
    #
    # @example Basic Usage
    #   RadioButton.new(
    #     form_state: fs,
    #     name: :operator,
    #     value: "AND",
    #     label: "And"
    #   )
    #
    # @example Inline layout
    #   RadioButton.new(
    #     form_state: fs,
    #     name: :operator,
    #     value: "OR",
    #     label: "Or",
    #     inline: true
    #   )
    class RadioButton < BaseControl
      attr_reader :value, :label, :checked
      attr_accessor :name, :form_state

      # Initializes a new RadioButton instance.
      #
      # @param form_state [SearchForm::Services::FormState] The shared form state object.
      # @param name [Symbol] The name for the radio button group.
      # @param value [String, Symbol] The value submitted when this radio button is selected.
      # @param label [String] The text to display in the label.
      # @param checked [Boolean] The initial checked state of the radio button.
      # @param help_text [String] Help text to be displayed alongside the radio button.
      # @param ** [Hash] Additional options passed to the `BaseControl` initializer.
      # rubocop:disable Metrics/ParameterLists
      def initialize(form_state:, name:, value:, label:, checked: false, help_text: nil, **)
        super(form_state: form_state, help_text: help_text, **)
        @name = name
        @value = value
        @label = label
        @checked = checked
      end
      # rubocop:enable Metrics/ParameterLists

      # Overrides the base method to add radio-button-specific data attributes.
      # It calls `super` to get base data attributes, then merges in attributes
      # for Stimulus-driven behaviors.
      #
      # @return [Hash] A hash of data attributes for the radio button input.
      def data_attributes
        data = super
        add_radio_toggle_attributes(data)
        add_controls_select_attributes(data)
        data
      end

      # Overrides the base method to support an `:inline` layout option.
      #
      # @return [String] The CSS class for the wrapping container.
      def default_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      # Prepares the final hash of HTML options specifically for the radio button input.
      # This builds upon the base `html_options` but sets radio-button-specific
      # values and handles options like `:disabled` and `:inline`.
      #
      # @return [Hash] A clean hash of HTML options for the `form.radio_button` helper.
      def radio_button_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: element_id
        }

        html_opts["aria-describedby"] = help_text_id if show_inline_help_text?
        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)
        html_opts[:data] = data_attributes if data_attributes.any?

        # Exclude special options that are handled elsewhere.
        html_opts.merge(options.except(:inline, :container_class))
      end

      private

        # Implements the abstract method from `BaseControl`.
        # Uses both the `name` and `value` to create a unique ID, which is
        # essential for correctly associating labels with radio buttons in a group.
        #
        # @return [Array<Symbol, String>] The parts for the HTML ID.
        def id_parts
          [name, value]
        end

        # Adds data attributes for a Stimulus toggle action.
        #
        # @param data [Hash] The hash of data attributes to be modified.
        # @return [void]
        def add_radio_toggle_attributes(data)
          return unless stimulus_config[:radio_toggle]

          data[:search_form_target] = "radioToggle"
          data[:action] = "change->search-form#toggleFromRadio"
        end

        # Adds a data attribute that controls the visibility of another element.
        #
        # @param data [Hash] The hash of data attributes to be modified.
        # @return [void]
        def add_controls_select_attributes(data)
          return unless stimulus_config[:controls_select]

          data[:controls_select] = stimulus_config[:controls_select].to_s
        end
    end
  end
end
