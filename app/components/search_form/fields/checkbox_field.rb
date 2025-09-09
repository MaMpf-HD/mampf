module SearchForm
  module Fields
    # Renders a single checkbox control within the standard field layout.
    class CheckboxField < Field
      attr_reader :checked, :stimulus_config

      # Initializes a new CheckboxField.
      #
      # @param name [Symbol] The name of the field.
      # @param label [String] The label text for the field.
      # @param checked [Boolean] The initial checked state of the checkbox. Defaults to `false`.
      # @param stimulus [Hash] Configuration for Stimulus.js controllers.
      # @param options [Hash] A hash of options passed to the base `Field` class.
      def initialize(name:, label:, checked: false, stimulus: {}, **options)
        @checked = checked
        @stimulus_config = stimulus

        super(
          name: name,
          label: label,
          **options
        )

        extract_and_update_field_classes!(options)
      end

      # Generates the full, unique HTML ID for the checkbox element.
      #
      # @return [String] The full element ID, including form scope and context.
      def element_id
        form_state.element_id_for(name)
      end

      # Generates the identifier for the label's `for` attribute.
      #
      # @return [String] The identifier, which the form builder will scope correctly.
      def label_for
        form_state.label_for(name)
      end

      # Builds the data attributes for the checkbox input.
      # Includes any data attributes from options plus Stimulus-driven attributes.
      #
      # @return [Hash] A hash of data attributes.
      def data_attributes
        data = options[:data] || {}
        add_toggle_attributes(data)
        add_radio_group_toggle_attributes(data)
        data
      end

      # Prepares the final hash of HTML options for the checkbox input element.
      #
      # @return [Hash] A clean hash of HTML options for the form.check_box helper.
      def checkbox_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: element_id
        }

        html_opts["aria-describedby"] = help_text_id if show_help_text?
        html_opts[:data] = data_attributes if data_attributes.any?
        html_opts.merge(options.except(:container_class, :data))
      end

      # @return [String] The help text ID for accessibility
      def help_text_id
        "#{element_id}_help"
      end

      # Overrides the base method to provide no default classes.
      # The styling is handled by the checkbox input itself.
      #
      # @return [Array] An empty array.
      def default_field_classes
        []
      end

      private

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

        # Adds data attributes for toggling a group of radio buttons.
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
