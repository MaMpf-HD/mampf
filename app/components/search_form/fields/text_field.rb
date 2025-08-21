module SearchForm
  module Fields
    class TextField < Field
      def initialize(name:, label:, column_class: "col-4", **options)
        # Extract field-specific classes and pass to unified system
        field_classes = extract_field_classes(options)

        super(
          name: name,
          label: label,
          column_class: column_class,
          field_class: field_classes,
          **options
        )
      end

      protected

        def default_field_classes
          ["form-control"] # Bootstrap form-control class
        end
    end
  end
end
