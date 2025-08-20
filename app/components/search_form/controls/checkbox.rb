# app/components/search_form/controls/checkbox.rb
module SearchForm
  module Controls
    class Checkbox < BaseControl
      attr_reader :name, :label, :checked

      def initialize(form_state:, name:, label:, checked: false, **)
        super(form_state: form_state, **)
        @name = name
        @label = label
        @checked = checked
      end

      # Generate data attributes from stimulus config
      def data_attributes
        data = super
        add_toggle_attributes(data)
        add_radio_group_toggle_attributes(data)
        data
      end

      def checkbox_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: element_id
        }
        html_opts[:data] = data_attributes if data_attributes.any?
        html_opts.merge(options.except(:container_class))
      end

      def label_id
        label_for
      end

      private

        def id_parts
          [name]
        end

        # Add basic toggle functionality data attributes
        def add_toggle_attributes(data)
          return unless stimulus_config[:toggle]

          data[:search_form_target] = "allToggle"
          data[:action] = "change->search-form#toggleFromCheckbox"
        end

        # Add radio group toggle functionality data attributes
        def add_radio_group_toggle_attributes(data)
          return unless stimulus_config[:toggle_radio_group]

          data[:action] = build_radio_toggle_action(data[:action])
          data[:toggle_radio_group] = stimulus_config[:toggle_radio_group]

          return unless stimulus_config[:default_radio_value]

          data[:default_radio_value] = stimulus_config[:default_radio_value]
        end

        # Build the combined action string for radio group toggle
        def build_radio_toggle_action(existing_action)
          radio_action = "change->search-form#toggleRadioGroup"

          return radio_action if existing_action.blank?

          "#{existing_action} #{radio_action}"
        end
    end
  end
end
