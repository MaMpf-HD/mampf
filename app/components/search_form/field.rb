module SearchForm
  class Field < ViewComponent::Base
    attr_reader :name, :label, :column_class, :help_text, :form, :options, :content
    attr_accessor :context

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

    def with_form(form)
      @form = form
      self
    end

    # Allow all field components to accept an extra block chunk
    def with_content(&block)
      @content = block if block
      self
    end

    # Generate a unique ID based on context AND form scope
    def element_id
      scope_prefix = form&.object_name || "search"
      context_part = context.present? ? "_#{context}" : ""
      "#{scope_prefix}#{context_part}_#{name}"
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
