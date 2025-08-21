module SearchForm
  module Fields
    class SelectField < Field
      attr_reader :collection

      def initialize(name:, label:, collection:, **options)
        @collection = collection

        super(
          name: name,
          label: label,
          **options
        )

        # Extract and update field classes after initialization
        extracted_classes = css.extract_field_classes(options)
        @field_class = [field_class, extracted_classes].compact.join(" ").strip
      end

      # Options hash for the select tag (the second parameter to form.select)
      def select_tag_options
        {}
      end

      def default_field_classes
        ["form-select"] # Bootstrap form-select class
      end
    end
  end
end
