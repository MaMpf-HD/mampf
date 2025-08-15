module Search
  class MultiSelectComponent < ViewComponent::Base
    attr_reader :name, :label, :collection, :column_class, :help_text, :all_toggle_name, :options,
                :form, :content

    def initialize(name:, label:, collection:, column_class: "col-5",
                   help_text: nil, all_toggle_name: nil, **options)
      super()
      @name = name
      @label = label
      @collection = collection
      @column_class = column_class
      @help_text = help_text
      @all_toggle_name = all_toggle_name || "all_#{name.to_s.sub(/_ids$/, "s")}"
      @options = options.reverse_merge(
        multiple: true,
        class: "selectize",
        disabled: true,
        required: true
      )
    end

    def with_form(form)
      @form = form
      self
    end
  end
end
