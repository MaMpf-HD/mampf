module SearchForm
  module Controls
    class Checkbox < ViewComponent::Base
      attr_reader :form, :name, :label, :checked, :options, :stimulus_config

      def initialize(form:, name:, label:, checked: false, stimulus: {}, **options)
        super()
        @form = form
        @name = name
        @label = label
        @checked = checked
        @stimulus_config = stimulus
        @options = options
      end

      # Generate data attributes from stimulus config
      def data_attributes
        return options[:data] || {} if stimulus_config.empty?

        data = options[:data] || {}

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
            data[:default_radio_value] = stimulus_config[:default_radio_value]
          end
        end

        data
      end
    end
  end
end
