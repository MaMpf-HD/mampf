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

        extract_and_update_field_classes!(options)
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
