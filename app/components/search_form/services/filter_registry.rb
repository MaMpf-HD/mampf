# FilterRegistry is responsible for managing and dynamically generating filter methods
# for SearchForm components.
#
# This service provides a declarative configuration system for defining available filters
# and their optional enhancement methods. It automatically generates corresponding methods
# on the SearchForm class, providing a clean API for adding filters to search forms.
#
# @example Basic filter configuration
#   FILTERS = {
#     fulltext: {},                    # Simple filter, generates add_fulltext_filter
#     tag: {                          # Filter with additional methods
#       additional_methods: {
#         with_operators: :with_operator_radios
#       }
#     }
#   }
#
# @example Generated methods on SearchForm
#   search_form.add_fulltext_filter(placeholder: "Search...")
#   search_form.add_tag_filter(collection: tags)
#   search_form.add_tag_filter_with_operators(collection: tags)
#
# @example Usage in SearchForm
#   class SearchForm < ViewComponent::Base
#     def filter_registry
#       @filter_registry ||= Services::FilterRegistry.new(self)
#     end
#
#     Services::FilterRegistry.generate_methods_for(self)
#   end
#
# The registry maintains a clean separation between filter configuration and
# the SearchForm component, making it easy to add new filters or modify
# existing ones without touching the main component code.
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
      #
      # @param search_form [SearchForm::SearchForm] The search form instance that will
      #   receive the generated filter instances
      def initialize(search_form)
        @search_form = search_form
        @form_state = search_form.form_state
      end

      # Dynamically generates filter methods on the provided class.
      #
      # This method creates two types of methods for each configured filter:
      # - Standard methods: add_[filter_name]_filter(**options)
      # - Enhanced methods: add_[filter_name]_filter_[method_suffix](*args, **options)
      #
      # @param klass [Class] The class (typically SearchForm) to add methods to
      #
      # @example Generated method signatures
      #   # For filter_name: :tag
      #   add_tag_filter(**options)
      #   add_tag_filter_with_operators(*args, **options)
      #
      # @return [void]
      def self.generate_methods_for(klass)
        FILTERS.each do |filter_name, config|
          filter_class = "SearchForm::Filters::#{filter_name.to_s.camelize}Filter"

          # Standard add_*_filter method
          klass.define_method("add_#{filter_name}_filter") do |**options|
            filter = filter_class.constantize.new(form_state: @form_state, **options)
            with_field(filter)
            # Return the filter instance to allow for method chaining and for inspection in tests.
            filter
          end

          # Generate additional methods if specified
          next unless config[:additional_methods]

          config[:additional_methods].each do |method_suffix, chain_method|
            klass.define_method("add_#{filter_name}_filter_#{method_suffix}") do |*args, **options|
              filter = filter_class.constantize.new(form_state: @form_state, **options)
              enhanced_filter = filter.send(chain_method, *args)
              with_field(enhanced_filter)
              # Return the filter instance to allow for method chaining and for inspection in tests.
              enhanced_filter
            end
          end
        end
      end

      # Returns the list of available filter names.
      #
      # This method is primarily useful for testing and introspection, allowing
      # verification that the expected filters are configured.
      #
      # @return [Array<Symbol>] Array of filter names that can be used to generate methods
      #
      # @example
      #   registry.available_filters
      #   # => [:medium_type, :teachable, :tag, :editor, ...]
      def available_filters
        FILTERS.keys.freeze
      end
    end
  end
end
