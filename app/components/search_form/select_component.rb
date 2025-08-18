module SearchForm
  class SelectComponent < FormFieldComponent
    attr_reader :collection

    def initialize(name:, label:, collection:, column_class: "col-2", **)
      @collection = collection
      super(name: name, label: label, column_class: column_class, **)
    end

    protected

      def process_options(options)
        options.reverse_merge(class: "form-select")
      end
  end
end
