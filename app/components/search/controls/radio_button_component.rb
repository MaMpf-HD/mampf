# app/components/search/controls/radio_button_component.rb
module Search
  module Controls
    class RadioButtonComponent < ViewComponent::Base
      attr_reader :form, :name, :value, :label, :checked, :options, :stimulus_config

      def initialize(form:, name:, value:, label:, checked: false, stimulus: {}, **options)
        super()
        @form = form
        @name = name
        @value = value
        @label = label
        @checked = checked
        @stimulus_config = stimulus
        @options = options
      end

      def with_form(form)
        @form = form
        self
      end

      def data_attributes
        result = options[:data] || {}

        unless stimulus_config.empty?
          if stimulus_config[:radio_toggle]
            result[:search_form_target] = "radioToggle"
            result[:action] = "change->search-form#toggleFromRadio"
          end

          if stimulus_config[:controls_select]
            result[:controls_select] = stimulus_config[:controls_select].to_s
          end

          # Add any other stimulus config as direct data attributes
          stimulus_config.each do |key, value|
            result[key] = value.to_s unless [:radio_toggle, :controls_select].include?(key)
          end
        end

        result
      end
    end
  end
end
