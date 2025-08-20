# app/components/search_form/controls/radio_button.rb
module SearchForm
  module Controls
    class RadioButton < BaseControl
      attr_reader :name, :value, :label, :checked

      def initialize(form_state:, name:, value:, label:, checked: false, **)
        super(form_state: form_state, **)
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

      def label_id
        label_for
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
