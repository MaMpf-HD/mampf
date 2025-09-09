module SearchForm
  module Fields
    # Renders a single checkbox control within the standard field layout.
    class CheckboxField < ViewComponent::Base
      attr_reader :checked, :stimulus_config, :field_data

      def initialize(name:, label:, form_state:, checked: false, stimulus: {}, **options)
        super()
        @checked = checked
        @stimulus_config = stimulus

        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: options[:help_text],
          form_state: form_state,
          options: options.dup
        )

        # Override the default_field_classes method (checkboxes don't have field classes)
        field_data.define_singleton_method(:default_field_classes) do
          []
        end

        field_data.extract_and_update_field_classes!(options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :container_class, :show_help_text?,
               :show_content?, :content, :options, to: :field_data

      # Form state interface
      delegate :form_state, to: :field_data
      
      def form_state=(new_form_state)
        field_data.form_state = new_form_state
      end

      def with_form(form)
        field_data.form_state.with_form(form)
        self
      end

      def with_content(&block)
        field_data.with_content(&block)
        self
      end

      def element_id
        form_state.element_id_for(name)
      end

      def label_for
        form_state.label_for(name)
      end

      def help_text_id
        "#{element_id}_help"
      end

      def data_attributes
        data = options[:data] || {}
        add_toggle_attributes(data)
        add_radio_group_toggle_attributes(data)
        data
      end

      def checkbox_html_options
        {
          class: "form-check-input",
          checked: checked,
          id: element_id,
          "aria-describedby": (help_text_id if show_help_text?),
          data: (data_attributes if data_attributes.any?)
        }.compact.merge(options.except(:container_class, :data))
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      private

        def add_toggle_attributes(data)
          return unless stimulus_config[:toggle]
          data[:search_form_target] = "allToggle"
          data[:action] = "change->search-form#toggleFromCheckbox"
        end

        def add_radio_group_toggle_attributes(data)
          return unless stimulus_config[:toggle_radio_group]

          data[:action] = build_radio_toggle_action(data[:action])
          data[:toggle_radio_group] = stimulus_config[:toggle_radio_group]
          data[:default_radio_value] = stimulus_config[:default_radio_value] if stimulus_config[:default_radio_value]
        end

        def build_radio_toggle_action(existing_action)
          radio_action = "change->search-form#toggleRadioGroup"
          existing_action.present? ? "#{existing_action} #{radio_action}" : radio_action
        end
    end
  end
end