module SearchForm
  module Fields
    class TextField < Field
      def initialize(name:, label:, **options)
        super

        extract_and_update_field_classes!(options)
      end

      def default_field_classes
        ["form-control"] # Bootstrap form-control class
      end
    end
  end
end
