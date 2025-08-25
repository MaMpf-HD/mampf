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
        tag: {
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
        tag_title: {},
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

      def initialize(search_form)
        @search_form = search_form
      end

      def self.generate_methods_for(klass)
        FILTERS.each do |filter_name, config|
          filter_class = "SearchForm::Filters::#{filter_name.to_s.camelize}Filter"

          # Standard add_*_filter method
          klass.define_method("add_#{filter_name}_filter") do |**options|
            filter = filter_class.constantize.new(**options)
            with_field(filter)
            filter # Return for testing
          end

          # Generate additional methods if specified
          next unless config[:additional_methods]

          config[:additional_methods].each do |method_suffix, chain_method|
            klass.define_method("add_#{filter_name}_filter_#{method_suffix}") do |*args, **options|
              filter = filter_class.constantize.new(**options)
              enhanced_filter = filter.send(chain_method, *args)
              with_field(enhanced_filter)
              enhanced_filter # Return for testing
            end
          end
        end
      end

      # Utility method for testing
      def available_filters
        FILTERS.keys
      end
    end
  end
end
