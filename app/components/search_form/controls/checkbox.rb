module SearchForm
  module Controls
    # Renders a single checkbox control and its associated label.
    # This class extends `BaseControl` and adds specific logic for handling
    # checkbox state and generating Stimulus.js data attributes for advanced
    # toggling behaviors within the search form.
    #
    # @example Basic Usage
    #   Checkbox.new(form_state: fs, name: :all, label: "Select all")
    #
    # @example With Stimulus Toggle
    #   Checkbox.new(
    #     form_state: fs,
    #     name: :all,
    #     label: "Select all",
    #     stimulus: { toggle: true }
    #   )
    class Checkbox < BaseControl
      attr_reader :name, :label, :checked

      # Initializes a new Checkbox instance.
      #
      # @param form_state [SearchForm::Services::FormState] The shared form state object.
      # @param name [Symbol] The name of the checkbox, used for ID generation and form submission.
      # @param label [String] The text to display in the label associated with the checkbox.
      # @param checked [Boolean] The initial checked state of the checkbox.
      # @param ** [Hash] Additional options passed to the `BaseControl` initializer.
      # rubocop:disable Metrics/ParameterLists
      def initialize(form_state:, name:, label:, checked: false, help_text: nil, **)
        super(form_state: form_state, help_text: help_text, **)
        @name = name
        @label = label
        @checked = checked
      end
      # rubocop:enable Metrics/ParameterLists

      # Overrides the base method to add Stimulus-driven data attributes.
      # It calls `super` to get any data attributes from the options, then merges
      # in attributes for toggling other elements based on the `stimulus_config`.
      #
      # @return [Hash] A hash of data attributes for the checkbox input.
      def data_attributes
        data = super
        add_toggle_attributes(data)
        add_radio_group_toggle_attributes(data)
        data
      end

      # Prepares the final hash of HTML options specifically for the checkbox input element.
      # This method builds upon the base `html_options` but sets checkbox-specific
      # values like `class`, `checked`, and `id`.
      #
      # @return [Hash] A clean hash of HTML options for the `form.check_box` helper.
      def checkbox_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: element_id
        }

        html_opts["aria-describedby"] = help_text_id if show_inline_help_text?
        html_opts[:data] = data_attributes if data_attributes.any?
        html_opts.merge(options.except(:container_class))
      end

      private

        # Implements the abstract method from `BaseControl`.
        # Uses the checkbox's `name` as the unique part for ID generation.
        #
        # @return [Array<Symbol>] The parts for the HTML ID.
        def id_parts
          [name]
        end

        # Adds data attributes for a basic Stimulus toggle action.
        # This is triggered when `stimulus_config[:toggle]` is true.
        #
        # @param data [Hash] The hash of data attributes to be modified.
        # @return [void]
        def add_toggle_attributes(data)
          return unless stimulus_config[:toggle]

          data[:search_form_target] = "allToggle"
          data[:action] = "change->search-form#toggleFromCheckbox"
        end

        # Adds data attributes for a more complex action: toggling a group of radio buttons.
        # This is triggered when `stimulus_config[:toggle_radio_group]` is present.
        #
        # @param data [Hash] The hash of data attributes to be modified.
        # @return [void]
        def add_radio_group_toggle_attributes(data)
          return unless stimulus_config[:toggle_radio_group]

          data[:action] = build_radio_toggle_action(data[:action])
          data[:toggle_radio_group] = stimulus_config[:toggle_radio_group]

          return unless stimulus_config[:default_radio_value]

          data[:default_radio_value] = stimulus_config[:default_radio_value]
        end

        # Helper method to build the combined Stimulus action string.
        # It safely appends the radio toggle action to any existing actions.
        #
        # @param existing_action [String, nil] The existing Stimulus action string.
        # @return [String] The combined action string.
        def build_radio_toggle_action(existing_action)
          radio_action = "change->search-form#toggleRadioGroup"

          return radio_action if existing_action.blank?

          "#{existing_action} #{radio_action}"
        end
    end
  end
end
