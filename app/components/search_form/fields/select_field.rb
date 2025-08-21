module SearchForm
  module Fields
    class SelectField < Field
      attr_reader :collection

      def initialize(name:, label:, collection:, **options)
        @collection = collection

        # Extract field-specific classes and pass to unified system
        field_classes = extract_field_classes(options)

        super(
          name: name,
          label: label,
          field_class: field_classes,
          **options
        )
      end

      # Options hash for the select tag (the second parameter to form.select)
      def select_tag_options
        {}
      end

      protected

        def default_field_classes
          ["form-select"] # Bootstrap form-select class
        end
    end
  end
end
