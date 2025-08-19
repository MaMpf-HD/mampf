# app/components/search/controls/radio_button_component.rb
module SearchForm
  module Controls
    class RadioButton < ViewComponent::Base
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
        end

        result
      end

      def container_class
        if options[:container_class]
          options[:container_class]
        elsif options[:inline]
          "form-check form-check-inline"
        else
          "form-check mb-2"
        end
      end

      def radio_button_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked
        }

        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)

        html_opts[:data] = data_attributes if data_attributes.any?

        html_opts.merge(options.except(:inline))
      end

      def label_id
        "#{name}_#{value}"
      end
    end
  end
end
