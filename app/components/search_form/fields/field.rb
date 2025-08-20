# app/components/search_form/fields/field.rb
module SearchForm
  module Fields
    class Field < ViewComponent::Base
      attr_reader :name, :label, :column_class, :help_text, :options, :content
      attr_accessor :form_state

      def initialize(name:, label:, column_class:, help_text: nil, **options)
        super()
        @name = name
        @label = label
        @column_class = column_class
        @help_text = help_text
        @options = process_options(options)
      end

      def container_classes
        "#{column_class} mb-3 form-field-group"
      end

      # Delegate form access to form_state
      def form
        form_state&.form
      end

      # Delegate context access to form_state
      def context
        form_state&.context
      end

      def with_form(form)
        form_state&.with_form(form)
        self
      end

      # Allow all field components to accept an extra block chunk
      def with_content(&block)
        @content = block if block
        self
      end

      # Generate a unique ID using form_state
      def element_id
        form_state&.element_id_for(name) || name.to_s
      end

      # Common conditional methods used by templates
      def show_help_text?
        help_text.present?
      end

      def show_content?
        content.present?
      end

      # Common method for building HTML options with ID
      def html_options_with_id(additional_options = {})
        options.merge(id: element_id).merge(additional_options)
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      protected

        # To be overridden by subclasses
        def process_options(options)
          options
        end
    end
  end
end
