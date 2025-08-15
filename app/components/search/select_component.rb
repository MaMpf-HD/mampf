module Search
  class SelectComponent < ViewComponent::Base
    attr_reader :name, :label, :collection, :column_class, :help_text, :options, :form

    def initialize(name:, label:, collection:, column_class: "col-2",
                   help_text: nil, **options)
      super()
      @name = name
      @label = label
      @collection = collection
      @column_class = column_class
      @help_text = help_text
      @options = options.reverse_merge(class: "form-select")
    end

    def with_form(form)
      @form = form
      self
    end
  end
end
