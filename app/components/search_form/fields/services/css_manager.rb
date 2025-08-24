module SearchForm
  module Fields
    module Services
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
