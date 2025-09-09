module SearchForm
  module Fields
    # RadioButtonField is now a first-class Field component.
    # Promoted from Controls::RadioButton with minimal changes.
    class RadioButtonField < Field
      attr_reader :value, :checked
      attr_accessor :name, :form_state

      def initialize(name:, value:, label:, checked: false, help_text: nil, container_class: nil,
                     **)
        super(name: name, label: label, help_text: help_text, **)
        @value = value
        @checked = checked
        @custom_container_class = container_class # Store custom container class
      end

      # Update the container class method to use the override if provided
      def container_class
        return @custom_container_class if @custom_container_class

        default_container_class
      end

      # Keep the original data_attributes method from Controls::RadioButton
      def data_attributes
        data = options[:data] || {}
        add_radio_toggle_attributes(data)
        add_controls_select_attributes(data)
        data
      end

      # Keep the original container class logic
      def default_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      # Keep the original radio_button_html_options method name and logic
      def radio_button_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: html.element_id
        }

        html_opts["aria-describedby"] = html.help_text_id if show_help_text?
        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)
        html_opts[:data] = data_attributes if data_attributes.any?

        html_opts.merge(options.except(:inline, :container_class, :stimulus))
      end

      private

        # Keep original stimulus helper methods
        def add_radio_toggle_attributes(data)
          return unless stimulus_config[:radio_toggle]

          data[:search_form_target] = "radioToggle"
          data[:action] = "change->search-form#toggleFromRadio"
        end

        def add_controls_select_attributes(data)
          return unless stimulus_config[:controls_select]

          data[:controls_select] = stimulus_config[:controls_select].to_s
        end

        def stimulus_config
          options[:stimulus] || {}
        end
    end
  end
end
