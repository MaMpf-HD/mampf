module Search
  class MultiSelectComponent < FormFieldComponent
    attr_reader :collection, :all_toggle_name

    def initialize(name:, label:, collection:, column_class: "col-5",
                   all_toggle_name: nil, **)
      @collection = collection
      @all_toggle_name = all_toggle_name || "all_#{name.to_s.sub(/_ids$/, "s")}"
      @content = nil
      super(name: name, label: label, column_class: column_class, **)
    end

    protected

      def process_options(options)
        options.reverse_merge(
          multiple: true,
          class: "selectize",
          disabled: true,
          required: true
        )
      end
  end
end
