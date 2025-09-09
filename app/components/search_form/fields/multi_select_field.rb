module SearchForm
  module Fields
    # Renders a multi-select field, typically enhanced with a JavaScript library
    # like Selectize. This component now focuses solely on rendering the select
    # element itself, with any associated controls (checkboxes, radio buttons)
    # being handled by the parent filter components through composition.
    class MultiSelectField < ViewComponent::Base
      attr_reader :collection, :data_builder, :field_data

      def initialize(name:, label:, collection:, form_state:, **options)
        super()
        @collection = collection

        # Process options with defaults
        processed_options = process_options(options)

        # Create field data object
        @field_data = FieldData.new(
          name: name,
          label: label,
          help_text: options[:help_text],
          form_state: form_state,
          options: processed_options,
          multiple: processed_options[:multiple],
          disabled: processed_options[:disabled],
          required: processed_options[:required],
          prompt: processed_options[:prompt],
          selected: processed_options[:selected]
        )

        # Override the default_field_classes method to provide selectize classes
        field_data.define_singleton_method(:default_field_classes) do
          ["selectize"]
        end

        # Extract and update field classes (must happen after defining default_field_classes)
        field_data.extract_and_update_field_classes!(processed_options)

        # Initialize service objects
        @data_builder = Services::DataAttributesBuilder.new(field_data)
      end

      # Delegate common methods to field_data
      delegate :name, :label, :help_text, :form, :container_class, :show_help_text?,
               :show_content?, :html, :content, to: :field_data

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

      def field_html_options(additional_options = {})
        html.field_html_options(additional_options.merge(data: data_builder.select_data_attributes))
      end

      delegate :select_tag_options, to: :html

      def default_prompt
        true
      end

      def default_field_classes
        ["selectize"]
      end

      private

        def process_options(opts)
          opts.reverse_merge(
            multiple: true,
            disabled: true,
            required: true,
            prompt: true
          )
        end
    end
  end
end