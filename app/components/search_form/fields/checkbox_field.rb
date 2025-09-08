module SearchForm
  module Fields
    # CheckboxField is now a first-class Field component.
    # No longer a wrapper around Controls::Checkbox.
    class CheckboxField < Field
      attr_reader :checked

      def initialize(name:, label:, checked: false, **)
        super(name: name, label: label, **)
        @checked = checked
      end

      def default_field_classes
        ["form-check-input"]
      end

      def default_container_class
        "form-check mb-2"
      end

      # Builds HTML options for the checkbox input
      def field_html_options(additional_options = {})
        html_opts = {
          class: field_class,
          checked: checked,
          id: html.element_id
        }

        html_opts["aria-describedby"] = html.help_text_id if show_help_text?
        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)
        html_opts[:data] = build_data_attributes if build_data_attributes.any?

        html_opts.merge(additional_options).merge(options.except(:container_class, :class,
                                                                 :field_class))
      end

      private

        # Build data attributes for Stimulus integration
        def build_data_attributes
          data = options[:data] || {}

          if options[:stimulus]&.dig(:toggle)
            data[:search_form_target] = "allToggle"
            data[:action] = "change->search-form#toggleFromCheckbox"
          end

          if options[:stimulus]&.dig(:toggle_radio_group)
            data[:action] = build_radio_toggle_action(data[:action])
            data[:toggle_radio_group] = options[:stimulus][:toggle_radio_group]

            if options[:stimulus][:default_radio_value]
              data[:default_radio_value] = options[:stimulus][:default_radio_value]
            end
          end

          data
        end

        def build_radio_toggle_action(existing_action)
          radio_action = "change->search-form#toggleRadioGroup"
          return radio_action if existing_action.blank?

          "#{existing_action} #{radio_action}"
        end
    end
  end
end
