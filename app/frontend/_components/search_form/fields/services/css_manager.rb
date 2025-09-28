module SearchForm
  module Fields
    module Services
      # A service class responsible for building the final CSS class string for a
      # form field element (e.g., an `<input>` or `<select>`). It consolidates
      # classes from multiple sources:
      # - Default classes defined by the field subclass (e.g., "form-control").
      # - User-provided classes from the `:class` option.
      # - A base `field_class` attribute on the field.
      class CssManager
        # Initializes a new CssManager.
        #
        # @param field_data [SearchForm::Fields::Services::FieldData] The field data object
        # that this manager serves.
        def initialize(field_data)
          @field_data = field_data
        end

        # This method is the primary interface for getting the final CSS class string
        # at render time.
        #
        # @return [String] The combined CSS class string.
        def field_css_classes
          [@field_data.field_class, additional_field_classes].compact.join(" ").strip
        end

        # Extracts and combines CSS classes from the provided options hash.
        # This is a helper method called by `FieldData#extract_and_update_field_classes!`
        # during initialization. It merges the field's `default_field_classes` with
        # any classes passed in the `:class` option.
        #
        # @param options [Hash] The options hash to extract classes from.
        # @return [String] The combined CSS class string from the options.
        def extract_field_classes(options)
          build_field_classes_from_options(options)
        end

        private

          attr_reader :field_data

          # A private helper that re-evaluates the field's main options hash at runtime.
          # This is used by the public `field_css_classes` method.
          def additional_field_classes
            build_field_classes_from_options(@field_data.options)
          end

          # The core logic for building a class string. It takes an options hash,
          # retrieves the field's default classes, appends the value of the `:class`
          # key from the hash, and returns a space-separated string.
          def build_field_classes_from_options(opts)
            classes = Array(@field_data.default_field_classes)
            classes << opts[:class] if opts[:class]
            classes.compact.join(" ")
          end
      end
    end
  end
end
