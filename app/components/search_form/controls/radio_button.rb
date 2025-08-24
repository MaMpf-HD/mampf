module SearchForm
  module Controls
    # Radio button control component for single selection from a group
    #
    # This control renders an individual radio button input with its label.
    # Radio buttons are typically used in groups where only one option can
    # be selected at a time. This component integrates with RadioGroup for
    # proper grouping and shared name attributes.
    #
    # Features:
    # - Single selection within a named group
    # - Value-based option representation
    # - Stimulus integration for dynamic behaviors
    # - Support for inline and block layouts
    # - Disabled state support
    # - Proper accessibility with label association
    #
    # @param value [String, Integer] The value submitted when this radio is selected
    # @param label [String] Display label for the radio button
    # @param checked [Boolean] Whether this radio is initially selected
    # @param name [String, Symbol] The shared name for the radio group
    # @param inline [Boolean] Whether to display inline or as block
    # @param disabled [Boolean] Whether the radio button is disabled
    #
    # @example Basic radio button
    #   RadioButton.new(
    #     form_state: form_state,
    #     name: :sort_by,
    #     value: "date",
    #     label: "Sort by Date",
    #     checked: false
    #   )
    #
    # @example Inline radio button
    #   RadioButton.new(
    #     form_state: form_state,
    #     name: :view_mode,
    #     value: "grid",
    #     label: "Grid View",
    #     inline: true
    #   )
    class RadioButton < BaseControl
      attr_reader :value, :label, :checked
      attr_accessor :name, :form_state

      def initialize(value:, label:, checked: false, **options)
        form_state = options.delete(:form_state)
        name = options.delete(:name)

        super(form_state: form_state, **options)
        @name = name
        @value = value
        @label = label
        @checked = checked
      end

      # Override to provide radio button specific data attributes
      def data_attributes
        data = super
        add_radio_toggle_attributes(data)
        add_controls_select_attributes(data)
        data
      end

      # Override to handle inline option
      def default_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      def radio_button_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: element_id
        }

        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)
        html_opts[:data] = data_attributes if data_attributes.any?

        # Exclude special options
        html_opts.merge(options.except(:inline, :container_class))
      end

      private

        # This is the single source of truth for this component's ID parts.
        def id_parts
          [name, value]
        end

        # Add radio toggle functionality data attributes
        def add_radio_toggle_attributes(data)
          return unless stimulus_config[:radio_toggle]

          data[:search_form_target] = "radioToggle"
          data[:action] = "change->search-form#toggleFromRadio"
        end

        # Add controls select functionality data attributes
        def add_controls_select_attributes(data)
          return unless stimulus_config[:controls_select]

          data[:controls_select] = stimulus_config[:controls_select].to_s
        end
    end
  end
end
