module SearchForm
  module Fields
    class RadioButtonField < Field
      attr_reader :value, :checked

      def initialize(name:, value:, label:, checked: false, **)
        super(name: name, label: label, **)
        @value = value
        @checked = checked
      end

      # Ensure radios use the correct wrapper based on :inline
      def default_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      # Override the default field classes since radio buttons have different styling
      def default_field_classes
        ["form-check-input"]
      end

      # Public helpers for template
      def element_id
        @element_id ||= form_state.element_id_for(name, value)
      end

      def help_text_id
        "#{element_id}_help"
      end

      # Builds HTML options for the radio button input
      def field_html_options(additional_options = {})
        html_opts = {
          class: field_class.presence || default_field_classes.join(" "),
          checked: checked,
          id: element_id,
          value: value
        }

        html_opts["aria-describedby"] = help_text_id if show_help_text?
        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)

        data_attrs = build_data_attributes
        html_opts[:data] = data_attrs if data_attrs.any?

        html_opts.merge(additional_options).merge(
          options.except(:inline, :container_class, :class, :field_class)
        )
      end

      private

        # Build data attributes for Stimulus integration
        def build_data_attributes
          data = options[:data] || {}

          if options[:stimulus]&.dig(:radio_toggle)
            data[:search_form_target] = "radioToggle"
            data[:action] = "change->search-form#toggleFromRadio"
          end

          if options[:stimulus]&.dig(:controls_select)
            data[:controls_select] = options[:stimulus][:controls_select].to_s
          end

          data
        end
    end
  end
end
