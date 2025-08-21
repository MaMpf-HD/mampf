module SearchForm
  module Fields
    class TextField < Field
      def initialize(name:, label:, **options)
        super

        # Extract and update field classes after initialization
        extracted_classes = css.extract_field_classes(options)
        @field_class = [field_class, extracted_classes].compact.join(" ").strip
      end

      def default_field_classes
        ["form-control"] # Bootstrap form-control class
      end
    end
  end
end
