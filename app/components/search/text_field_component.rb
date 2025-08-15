module Search
  class TextFieldComponent < ViewComponent::Base
    attr_reader :name, :label, :column_class, :help_text, :options, :form

    def initialize(name:, label:, column_class: "col-4", help_text: nil, **options)
      super()
      @name = name
      @label = label
      @column_class = column_class
      @help_text = help_text
      @options = options.reverse_merge(class: "form-control")
    end

    def with_form(form)
      @form = form
      self
    end
  end
end
