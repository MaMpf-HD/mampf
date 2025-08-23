module SearchForm
  module FilterRegistry
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

    def self.included(base)
      generate_filter_methods(base)
    end

    def self.generate_filter_methods(klass)
      FILTERS.each do |filter_name, config|
        filter_class = "SearchForm::Filters::#{filter_name.to_s.camelize}Filter"

        # Standard add_*_filter method
        klass.define_method("add_#{filter_name}_filter") do |**options|
          with_field(filter_class.constantize.new(**options))
        end

        # Generate additional methods if specified
        next unless config[:additional_methods]

        config[:additional_methods].each do |method_suffix, chain_method|
          klass.define_method("add_#{filter_name}_filter_#{method_suffix}") do |*args, **options|
            filter = filter_class.constantize.new(**options)

            # Handle both symbol methods and lambda methods
            enhanced_filter = if chain_method.is_a?(Proc)
              chain_method.call(*args).call(filter)
            else
              filter.send(chain_method, *args)
            end

            with_field(enhanced_filter)
          end
        end
      end
    end
  end
end
