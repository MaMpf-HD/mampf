module SearchForm
  module Fields
    # Multi-select field for filtering by programs.
    #
    # The field displays programs with their associated subjects formatted as
    # "Subject Name: Program Name" and sorted alphabetically. This provides clear
    # context for users when selecting from programs that may have similar names
    # across different subjects.
    #
    # @example Basic program field
    #   ProgramField.new(form_state: form_state)
    #
    # @example Program field with additional options
    #   ProgramField.new(
    #     form_state: form_state,
    #     disabled: false,
    #     data: { custom_attribute: "value" }
    #   )
    class ProgramField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new ProgramField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying multi-select field
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @multi_select_field = create_multi_select_field(
            name: :program_ids,
            label: I18n.t("basics.programs"),
            help_text: I18n.t("search.helpdesks.program_field"),
            collection: program_options,
            **options
          )

          @all_checkbox = create_all_checkbox(for_field_name: :program_ids)

          @checkbox_group_wrapper = Fields::Utilities::CheckboxGroupWrapper.new(
            parent_field: @multi_select_field,
            checkboxes: [@all_checkbox]
          )
        end

        def program_options
          Program.includes(:subject, :translations, subject: :translations)
                 .map { |p| [p.name_with_subject, p.id] }
                 .natural_sort_by(&:first)
        end
    end
  end
end
