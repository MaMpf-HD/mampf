module SearchForm
  module Fields
    module Services
      # CSS management service for form field styling
      #
      # This service object handles CSS class management for form fields,
      # combining default classes with custom classes and runtime additions.
      # It provides a clean separation of concerns for styling logic.
      #
      # Features:
      # - Combines default field classes with custom options
      # - Handles runtime CSS class additions
      # - Provides clean string output for HTML class attributes
      # - Supports both static and dynamic class management
      #
      # @example Basic usage
      #   css_manager = CssManager.new(field)
      #   css_manager.field_css_classes
      #   # => "form-control custom-class"
      #
      # The service is initialized with a field instance and provides
      # methods to extract and combine CSS classes from various sources.
      class CssManager
        def initialize(field)
          @field = field
        end

        def field_css_classes
          [@field.field_class, additional_field_classes].compact.join(" ").strip
        end

        # Extract classes from options, combining with defaults from field
        def extract_field_classes(options)
          build_field_classes_from_options(options)
        end

        private

          attr_reader :field

          # Build additional field classes for runtime use
          def additional_field_classes
            build_field_classes_from_options(@field.options)
          end

          # Common logic for building field classes
          def build_field_classes_from_options(opts)
            classes = Array(@field.default_field_classes)
            classes << opts[:class] if opts[:class]
            classes.compact.join(" ")
          end
      end
    end
  end
end
