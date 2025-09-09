module SearchForm
  module Fields
    class RadioButtonField < ViewComponent::Base
      attr_reader :value, :checked, :field_data
      attr_accessor :name, :form_state

      def initialize(name:, value:, label:, form_state:, checked: false, help_text: nil, 
                     container_class: nil, **options)
        super()
        @value = value
        @checked = checked
        @custom_container_class = container_class # Store custom container class

        # Process options
        processed_options = options.dup

        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: help_text,
          form_state: form_state,
          options: processed_options
        )

        # Override the default_field_classes method (radio buttons don't have field classes)
        field_data.define_singleton_method(:default_field_classes) do
          []
        end

        # Extract and update field classes
        field_data.extract_and_update_field_classes!(processed_options)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :show_help_text?, :show_content?, 
               :content, :options, :html, to: :field_data

      # Add form_state interface for SearchForm auto-injection
      def form_state
        field_data.form_state
      end

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

      # Update the container class method to use the override if provided
      def container_class
        return @custom_container_class if @custom_container_class

        default_container_class
      end

      def data_attributes
        data = options[:data] || {}
        add_radio_toggle_attributes(data)
        add_controls_select_attributes(data)
        data
      end

      # Keep the original container class logic
      def default_container_class
        options[:inline] ? "form-check form-check-inline" : "form-check mb-2"
      end

      # Generates the full, unique HTML ID for the radio button element.
      def element_id
        form_state.element_id_for(name, value: value)
      end

      # Generates the identifier for the label's `for` attribute.
      def label_for
        form_state.label_for(name, value: value)
      end

      # @return [String] The help text ID for accessibility
      def help_text_id
        "#{element_id}_help"
      end

      # Keep the original radio_button_html_options method name and logic
      def radio_button_html_options
        html_opts = {
          class: "form-check-input",
          checked: checked,
          id: element_id
        }

        html_opts["aria-describedby"] = help_text_id if show_help_text?
        html_opts[:disabled] = options[:disabled] if options.key?(:disabled)
        html_opts[:data] = data_attributes if data_attributes.any?

        html_opts.merge(options.except(:inline, :container_class, :stimulus))
      end

      # Overrides the base method to provide no default classes.
      # The styling is handled by the radio button input itself.
      def default_field_classes
        []
      end

      # A ViewComponent lifecycle callback that runs before rendering.
      # Ensures that the form builder has been set, preventing runtime errors.
      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      private

        # Keep original stimulus helper methods
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