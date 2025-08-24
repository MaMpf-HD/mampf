module SearchForm
  module Fields
    class Field < ViewComponent::Base
      attr_reader :name, :label, :container_class, :field_class, :help_text, :options,
                  :content, :css, :html, :prompt, :include_blank
      attr_accessor :form_state

      def initialize(name:, label:, **options)
        super()
        @name = name
        @label = label

        # Extract layout options with defaults
        @container_class = options.delete(:container_class) ||
                           "col-6 col-lg-3 mb-3 form-field-group"
        @field_class = options.delete(:field_class) || ""
        @help_text = options.delete(:help_text)

        # Extract prompt configuration with defaults
        @prompt = options.delete(:prompt) { default_prompt }
        @include_blank = options.delete(:include_blank)

        @options = process_options(options)

        # Make services accessible as public APIs
        @css = Services::CssManager.new(self)
        @html = Services::HtmlBuilder.new(self)
      end

      # Delegate form access to form_state
      delegate :form, to: :form_state

      delegate :context, to: :form_state

      def with_form(form)
        form_state.with_form(form)
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

      def selected
        options[:selected] # Method name now matches the option key
      end

      # Override in subclasses to set appropriate defaults
      def default_prompt
        false
      end

      protected

        # Call this in subclass initialize after super to extract field classes
        def extract_and_update_field_classes!(options)
          extracted_classes = css.extract_field_classes(options)
          @field_class = [field_class, extracted_classes].compact.join(" ").strip
        end

        def process_options(options)
          options
        end
    end
  end
end
