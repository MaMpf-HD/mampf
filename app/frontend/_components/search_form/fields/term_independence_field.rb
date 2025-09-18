module SearchForm
  module Fields
    # Checkbox for filtering by term independence.
    #
    # This allows users to filter for content independent of academic terms like
    # "Wintersemester <year>", i.e. "evergreen" content that is not tied to
    # specific academic periods.
    #
    # @example Basic term independence field
    #   TermIndependenceField.new(form_state: form_state)
    #
    # @example Term independence field with custom container
    #   TermIndependenceField.new(
    #     form_state: form_state,
    #     container_class: "col-md-6"
    #   )
    class TermIndependenceField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new TermIndependenceField component.
      #
      # This component is specialized for term independence filtering and uses
      # predefined field configuration without requiring additional setup.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying checkbox field,
      #   such as container_class or other styling attributes
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @checkbox_field = create_checkbox_field(
            name: :term_independent,
            label: I18n.t("admin.course.term_independent"),
            help_text: I18n.t("search.helpdesks.term_independence_field"),
            checked: false,
            **options
          )
        end
    end
  end
end
