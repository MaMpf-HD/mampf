module SearchForm
  module Fields
    class RadioButtonField < ViewComponent::Base
      attr_reader :value, :checked, :field_data

      def initialize(name:, value:, label:, form_state:, checked: false, help_text: nil, 
                     container_class: nil, **options)
        super()
        @value = value
        @checked = checked
        @custom_container_class = container_class

        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: help_text,
          form_state: form_state,
          options: options.dup
        )

        # Override the default_field_classes method
        field_data.define_singleton_method(:default_field_classes) do
          []
        end

        field_data.extract_and_update_field_classes!(options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :show_help_text?, :show_content?, 
               :content, :html, :options, to: :field_data

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

      def container_class
        return @custom_container_class if @custom_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      def element_id
        form_state.element_id_for(name, value: value)
      end

      def label_for
        form_state.label_for(name, value: value)
      end

      def help_text_id
        "#{element_id}_help"
      end

      def data_attributes
        data = options[:data] || {}
        add_radio_toggle_attributes(data)
        add_controls_select_attributes(data)
        data
      end

      def radio_button_html_options
        {
          class: "form-check-input",
          checked: checked,
          id: element_id,
          "aria-describedby": (help_text_id if show_help_text?),
          disabled: options[:disabled],
          data: (data_attributes if data_attributes.any?)
        }.compact.merge(options.except(:inline, :container_class, :stimulus))
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      private

        def add_radio_toggle_attributes(data)
          return unless stimulus_config[:radio_toggle]
          data[:search_form_target] = "radioToggle"
          data[:action] = "change->search-form#toggleFromRadio"
        end

        def add_controls_select_attributes(data)
          return unless stimulus_config[:controls_select]
          data[:controls_select] = stimulus_config[:controls_select].to_s
        end

        def stimulus_config
          options[:stimulus] || {}
        end
    end
  end
end