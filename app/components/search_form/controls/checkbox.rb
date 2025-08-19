module SearchForm
  module Controls
    class Checkbox < BaseControl
      attr_reader :name, :label, :checked

      def initialize(form:, name:, label:, checked: false, **)
        super(form: form, **)
        @name = name
        @label = label
        @checked = checked
      end

      # Generate data attributes from stimulus config
      def data_attributes
        data = super

        # Basic toggle functionality
        if stimulus_config[:toggle]
          data[:search_form_target] = "allToggle"
          data[:action] = "change->search-form#toggleFromCheckbox"
        end

        # Handle radio group toggling
        if stimulus_config[:toggle_radio_group]
          action = data[:action] || ""
          data[:action] = if action.empty?
            "change->search-form#toggleRadioGroup"
          else
            "#{action} change->search-form#toggleRadioGroup"
          end
          data[:toggle_radio_group] = stimulus_config[:toggle_radio_group]
          if stimulus_config[:default_radio_value]
            data[:default_radio_value] =
              stimulus_config[:default_radio_value]
          end
        end

        data
      end

      def checkbox_html_options
        html_opts = { class: "form-check-input", checked: checked }
        html_opts[:data] = data_attributes if data_attributes.any?
        html_opts.merge(options.except(:container_class))
      end
    end
  end
end
