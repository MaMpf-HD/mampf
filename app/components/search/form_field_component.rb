module Search
  class FormFieldComponent < ViewComponent::Base
    attr_reader :name, :label, :column_class, :help_text, :form, :options

    def initialize(name:, label:, column_class:, help_text: nil, **options)
      super()
      @name = name
      @label = label
      @column_class = column_class
      @help_text = help_text
      @options = process_options(options)
    end

    def with_form(form)
      @form = form
      self
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
