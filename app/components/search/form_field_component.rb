module Search
  class FormFieldComponent < ViewComponent::Base
    attr_reader :name, :label, :column_class, :help_text, :form, :context, :options, :content

    def initialize(name:, label:, column_class:, help_text: nil, context: nil, **options)
      super()
      @name = name
      @label = label
      @column_class = column_class
      @help_text = help_text
      @context = context

      options[:id] = "search_#{context}_#{name}" if context.present? && !options.key?(:id)
      @options = process_options(options)
    end

    def with_form(form)
      @form = form
      self
    end

    # Allow all field components to accept an extra block chunk
    def with_content(&block)
      @content = block if block
      self
    end

    # Generate an element ID based on context
    def element_id
      options[:id].presence || "search_#{context}_#{name}" if context.present?
      options[:id].presence || "search_#{name}"
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
