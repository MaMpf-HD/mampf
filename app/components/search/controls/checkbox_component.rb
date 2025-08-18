module Search
  module Controls
    class CheckboxComponent < ViewComponent::Base
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
        return {} if stimulus_config.empty?

        data = options[:data] || {}
        if stimulus_config[:toggle]
          data[:search_form_target] = "allToggle"
          data[:action] = "change->search-form#toggleFromCheckbox"
        end

        if stimulus_config[:tag_operators]
          data[:action] = "#{data[:action]} change->search-form#toggleTagOperators"
        end

        data
      end
    end
  end
end
