module SearchForm
  module Services
    class FilterRegistry
      # Filter configuration with optional additional methods
      FILTERS = {
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
        editor: {},
        medium_access: {},
        answer_count: {},
        fulltext: {},
        per_page: {},
        lecture_type: {},
        term: {},
        program: {},
        teacher: {},
        term_independence: {},
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

      # Initializes a new FilterRegistry instance.
      def initialize(search_form)
        @search_form = search_form
      end

      def self.generate_methods_for(klass)
        FILTERS.each do |filter_name, config|
          filter_class = "SearchForm::Filters::#{filter_name.to_s.camelize}Filter"

          # Standard add_*_filter method
          klass.define_method("add_#{filter_name}_filter") do |**options|
            filter = filter_registry.create_filter(filter_class, **options)
            with_field(filter)
            filter
          end

          # Generate additional methods if specified
          next unless config[:additional_methods]

          config[:additional_methods].each do |method_suffix, chain_method|
            klass.define_method("add_#{filter_name}_filter_#{method_suffix}") do |*args, **options|
              filter = filter_registry.create_filter(filter_class, **options)
              enhanced_filter = filter.send(chain_method, *args)
              with_field(enhanced_filter)
              enhanced_filter
            end
          end
        end
      end

      def available_filters
        FILTERS.keys.freeze
      end

      # Helper method to create filters with the correct parameters based on their type
      def create_filter(filter_class_name, **)
        filter_class = filter_class_name.constantize

        filter_class.new(form_state: @search_form.instance_variable_get(:@form_state), **)
      end
    end
  end
end
