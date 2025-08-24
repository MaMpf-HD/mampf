# Filter Registry Module
#
# This module provides dynamic method generation for search form filters.
# It maintains a centralized registry of all available filters and their
# configuration, then generates convenience methods like `add_*_filter`
# for each registered filter.
#
# Key features:
# - Centralized filter configuration with FILTERS hash
# - Auto-generation of standard add_*_filter methods
# - Support for additional methods (e.g., with_operators, with_inheritance)
# - Convention-based class name resolution
# - Clean separation between standard and enhanced filter variants
#
# The registry eliminates the need to manually define dozens of similar
# convenience methods while maintaining flexibility for special cases.

module SearchForm
  # Registry module that dynamically generates filter convenience methods
  #
  # This module is included in SearchForm::SearchForm to provide all the
  # `add_*_filter` methods. It uses metaprogramming to generate methods
  # based on the FILTERS configuration hash.
  #
  # @example Adding a new filter
  #   # Add to FILTERS hash:
  #   my_new_filter: {
  #     additional_methods: {
  #       with_special_option: :with_special_radios
  #     }
  #   }
  #
  #   # This automatically generates:
  #   # - add_my_new_filter(**options)
  #   # - add_my_new_filter_with_special_option(**options)
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
