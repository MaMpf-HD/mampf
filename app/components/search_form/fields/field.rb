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

      # Delegate to CSS manager
      delegate :container_classes, to: :css_manager

      delegate :field_css_classes, to: :css_manager

      # Delegate to HTML builder
      def html_options_with_id(additional_options = {})
        html_builder.html_options_with_id(additional_options)
      end

      def field_html_options(additional_options = {})
        html_builder.field_html_options(additional_options)
      end

      delegate :element_id, to: :html_builder

      delegate :label_for, to: :html_builder

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

      # Common conditional methods used by templates
      def show_help_text?
        help_text.present?
      end

      def show_content?
        content.present?
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      # Method for subclasses to extract field classes during initialization
      delegate :extract_field_classes, to: :css_manager

      # To be overridden by subclasses to provide default CSS classes
      def default_field_classes
        []
      end

      protected

        # To be overridden by subclasses
        def process_options(options)
          options
        end

      private

        def css_manager
          @css_manager ||= CssManager.new(self)
        end

        def html_builder
          @html_builder ||= HtmlBuilder.new(self)
        end
    end
  end
end
