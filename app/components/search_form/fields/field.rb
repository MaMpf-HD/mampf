module SearchForm
  module Fields
    class Field < ViewComponent::Base
      attr_reader :name, :label, :column_class, :field_class, :wrapper_class, :help_text, :options,
                  :content, :css, :html
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

        # Make services accessible as public APIs
        @css = CssManager.new(self)
        @html = HtmlBuilder.new(self)
      end

      # Delegate form access to form_state
      def form
        form_state&.form
      end

      def context
        form_state&.context
      end

      def with_form(form)
        form_state&.with_form(form)
        self
      end

      def with_content(&block)
        @content = block if block
        self
      end

      # Common conditional methods
      def show_help_text?
        help_text.present?
      end

      def show_content?
        content.present?
      end

      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end

      # To be overridden by subclasses
      def default_field_classes
        []
      end

      protected

        def process_options(options)
          options
        end
    end
  end
end
