module SearchForm
  module Fields
    # Text input field for full-text search queries.
    #
    # User input will be matched against content using full-text search capabilities.
    #
    # @example Basic fulltext search field
    #   FulltextField.new(form_state: form_state)
    #
    # @example Fulltext field with placeholder
    #   FulltextField.new(
    #     form_state: form_state,
    #     placeholder: "Enter search terms..."
    #   )
    class FulltextField < ViewComponent::Base
      include Mixins::CompositeFieldMixin

      attr_reader :options

      # Initializes a new FulltextField component.
      #
      # This component is specialized for full-text search and uses predefined
      # field name, label, and help text appropriate for search functionality.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param options [Hash] Additional options passed to the underlying text field,
      #   such as placeholder, maxlength, or custom styling attributes
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      private

        def setup_fields
          @text_field = create_text_field(
            name: :fulltext,
            label: I18n.t("basics.fulltext"),
            help_text: I18n.t("search.helpdesks.fulltext_field"),
            **options
          )
        end
    end
  end
end
