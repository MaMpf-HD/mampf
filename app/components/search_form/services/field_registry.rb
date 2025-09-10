module SearchForm
  module Services
    class FieldRegistry
      # Field configuration with optional additional methods
      FIELDS = {
        # Simple fields
        answer_count: {},
        editor: {},
        fulltext: {},
        lecture_type: {},
        medium_access: {},
        per_page: {},
        program: {},
        teacher: {},
        term: {},
        term_independence: {},

        # Composite fields
        medium_type: {},
        teachable: {
          additional_methods: {
            with_inheritance: :with_inheritance_radios
          }
        },
        tag: {},
        tag_old: {
          additional_methods: {
            with_operators: :with_operator_radios
          }
        },
        course: {
          additional_methods: {
            with_edited_courses: :with_edited_courses_button
          }
        },
        lecture_scope: {
          additional_methods: {
            with_lecture_options: :with_lecture_options
          }
        }
      }.freeze

      # Initializes a new FieldRegistry instance.
      def initialize(search_form)
        @search_form = search_form
      end

      def self.generate_methods_for(klass)
        FIELDS.each do |field_name, config|
          field_class = "SearchForm::Fields::#{field_name.to_s.camelize}Field"

          # Standard add_*_field method
          klass.define_method("add_#{field_name}_field") do |**options|
            field = field_registry.create_field(field_class, **options)
            with_field(field)
            field
          end

          # Generate additional methods if specified
          next unless config[:additional_methods]

          config[:additional_methods].each do |method_suffix, chain_method|
            klass.define_method("add_#{field_name}_field_#{method_suffix}") do |*args, **options|
              field = field_registry.create_field(field_class, **options)
              enhanced_field = field.send(chain_method, *args)
              with_field(enhanced_field)
              enhanced_field
            end
          end
        end
      end

      def available_fields
        FIELDS.keys.freeze
      end

      # Helper method to create fields with the correct parameters
      def create_field(field_class_name, **)
        field_class = field_class_name.constantize
        field_class.new(form_state: @search_form.instance_variable_get(:@form_state), **)
      end
    end
  end
end
