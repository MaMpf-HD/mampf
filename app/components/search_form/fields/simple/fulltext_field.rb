module SearchForm
  module Fields
    # Renders a text input field specifically for full-text search.
    # This component uses composition to build a text field, pre-configured
    # with a specific name, label, and help text suitable for a full-text
    # search query.
    class FulltextField < ViewComponent::Base
      attr_accessor :form_state

      # Initializes the FulltextField.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `TextField`, such as `:name`, `:label`, and `:help_text`.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param options [Hash] Additional options passed to the text field.
      #   This can be used to pass options like `:placeholder` or `:container_class`.
      def initialize(form_state:, **options)
        super()
        @form_state = form_state
        @options = options
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      def before_render
        setup_fields
      end

      private

        def setup_fields
          @text_field = Fields::TextField.new(
            name: :fulltext,
            label: I18n.t("basics.fulltext"),
            help_text: I18n.t("search.filters.helpdesks.fulltext_filter"),
            form_state: form_state,
            **@options
          ).with_form(form)
        end
    end
  end
end
