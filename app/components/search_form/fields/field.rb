module SearchForm
  module Fields
    class Field < ViewComponent::Base
      attr_reader :name, :label, :column_class, :field_class, :wrapper_class, :help_text, :options,
                  :content
      attr_accessor :form_state

      def initialize(name:, label:, column_class: "col-6 col-lg-3", field_class: "",
                     wrapper_class: "mb-3 form-field-group", help_text: nil, **options)
        super()
        @name = name
        @label = label
        @column_class = column_class
        @field_class = field_class
        @wrapper_class = wrapper_class
        @help_text = help_text
        @options = process_options(options)
      end

      # Unified CSS class methods
      def container_classes
        [column_class, wrapper_class].compact.join(" ")
      end

      def field_css_classes
        [field_class, additional_field_classes].compact.join(" ").strip
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
        form_state&.element_id_for(name)
      end

      # Public ID for the <label for="..."> attribute
      def label_for
        form_state&.label_for(name)
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

      # Common method for building HTML options with field CSS classes
      def field_html_options(additional_options = {})
        default_options = { class: field_css_classes }
        html_options_with_id(default_options.merge(additional_options))
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      protected

        # Extract classes from options, combining with defaults from subclass
        # This is used during initialization to build field_class
        def extract_field_classes(options)
          build_field_classes_from_options(options)
        end

        # Build additional field classes for runtime use
        # This is used by field_css_classes method
        def additional_field_classes
          build_field_classes_from_options(options)
        end

        # To be overridden by subclasses to provide default CSS classes
        def default_field_classes
          []
        end

        # To be overridden by subclasses
        def process_options(options)
          options
        end

      private

        # Common logic for building field classes
        def build_field_classes_from_options(opts)
          classes = Array(default_field_classes) # Get defaults from subclass
          classes << opts[:class] if opts[:class] # Add manually specified classes
          classes.compact.join(" ")
        end
    end
  end
end
