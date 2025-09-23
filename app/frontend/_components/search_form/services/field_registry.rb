module SearchForm
  module Services
    # A registry service that dynamically generates field addition methods for the
    # SearchForm component.
    # This class uses metaprogramming to create `add_*_field` methods that instantiate and register
    # field components with the form.
    #
    # The registry maintains a centralized list of all available field types and automatically
    # generates corresponding methods like `add_course_field`, `add_tag_field`, etc. This approach
    # ensures consistency in field registration while keeping the SearchForm component clean.
    #
    # @example Generated methods usage in SearchForm
    #   search_form.add_course_field(disabled: false)
    #   search_form.add_tag_field
    #   search_form.add_medium_type_field(current_user: user, purpose: "media")
    #
    # The generated methods follow the pattern:
    # - Method name: `add_{field_name}_field`
    # - Expected class: `SearchForm::Fields::{FieldName}Field`
    # - All methods accept keyword arguments that are passed to the field constructor
    class FieldRegistry
      # List of all available field types in the search form system.
      # Each symbol corresponds to a field class following the naming convention:
      # `:course` → `SearchForm::Fields::CourseField`
      FIELDS = [
        :answer_count, :course, :editor, :fulltext, :lecture_scope, :lecture_type,
        :medium_access, :medium_type, :per_page, :program, :tag, :teachable,
        :teacher, :term, :term_independence
      ].freeze

      # Initializes a new FieldRegistry instance.
      #
      # @param search_form [SearchForm::SearchForm] The search form instance that
      # will host the generated methods
      def initialize(search_form)
        @search_form = search_form
      end

      # Dynamically generates field addition methods on the provided class.
      # This method is called during SearchForm initialization to inject all the
      # `add_*_field` methods.
      #
      # For each field type in FIELDS, this creates a method that:
      # 1. Constantizes the appropriate field class name
      # 2. Instantiates the field with the form_state and provided options
      # 3. Registers the field with the SearchForm via `with_field`
      # 4. Returns the created field instance
      #
      # @param klass [Class] The class to define the methods on (typically SearchForm)
      # @return [void]
      #
      # @example Generated method structure
      #   def add_course_field(**options)
      #     field_class = "SearchForm::Fields::CourseField".constantize
      #     field = field_class.new(form_state: @form_state, **options)
      #     with_field(field)
      #     field
      #   end
      def self.generate_methods_for(klass)
        FIELDS.each do |field_name|
          klass.define_method("add_#{field_name}_field") do |**options|
            field_class = "SearchForm::Fields::#{field_name.to_s.camelize}Field".constantize
            field = field_class.new(form_state: @form_state, **options)
            with_field(field)
            field
          end
        end
      end
    end
  end
end
