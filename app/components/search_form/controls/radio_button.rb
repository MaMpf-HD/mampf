module SearchForm
  module Controls
    class RadioButton < BaseControl
      attr_reader :name, :value, :label, :checked

      def initialize(form:, name:, value:, label:, checked: false, **)
        super(form: form, **)
        @name = name
        @value = value
        @label = label
        @checked = checked
      end

      # Override to provide radio button specific data attributes
      def data_attributes
        data = super

        unless stimulus_config.empty?
          if stimulus_config[:radio_toggle]
            data[:search_form_target] = "radioToggle"
            data[:action] = "change->search-form#toggleFromRadio"
          end

          if stimulus_config[:controls_select]
            data[:controls_select] = stimulus_config[:controls_select].to_s
          end
        end

        data
      end

      # Override to handle inline option
      def default_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      def radio_button_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked
        }

        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)
        html_opts[:data] = data_attributes if data_attributes.any?

        # Exclude special options
        html_opts.merge(options.except(:inline, :container_class))
      end

      def label_id
        "#{name}_#{value}"
      end
    end
  end
end
