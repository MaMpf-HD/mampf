module SearchForm
  module Fields
    # Simple data class that holds field attributes and can be used by existing service objects
    class FieldData
      attr_reader :name, :label, :help_text, :options, :prompt,
                  :multiple, :disabled, :required, :selected, :css, :html
      attr_accessor :container_class, :field_class, :form_state

      def initialize(name:, label:, form_state:, help_text: nil, options: {},
                     multiple: nil, disabled: nil, required: nil, prompt: nil, selected: nil)
        @name = name
        @label = label
        @help_text = help_text
        @form_state = form_state
        @multiple = multiple
        @disabled = disabled
        @required = required
        @prompt = prompt
        @selected = selected
        @content_block = nil

        # Extract layout options with defaults (exactly like Field class)
        @container_class = options.delete(:container_class) ||
                           "col-6 col-lg-3 mb-3 form-field-group"
        @field_class = options.delete(:field_class) || ""

        # Store processed options
        @options = options

        # Make services accessible as public APIs (exactly like Field class)
        @css = Services::CssManager.new(self)
        @html = Services::HtmlBuilder.new(self)
      end

      delegate :form, to: :form_state
      delegate :context, to: :form_state

      def show_help_text?
        help_text.present?
      end

      def show_content?
        @content_block.present?
      end

      def with_content(&block)
        @content_block = block if block
        self
      end

      # Expose content for the template (like Field class)
      def content
        @content_block
      end

      # Hook for subclasses to provide default CSS classes (like Field class)
      def default_field_classes
        []
      end

      # Mimics the Field class method exactly
      def extract_and_update_field_classes!(options)
        extracted_classes = css.extract_field_classes(options)
        @field_class = [field_class, extracted_classes].compact.join(" ").strip
      end

      # A ViewComponent lifecycle callback that runs before rendering.
      # Ensures that the form builder has been set, preventing runtime errors.
      def before_render
        raise("Form not set for #{self.class.name}. Call with_form before rendering.") unless form
      end
    end
  end
end