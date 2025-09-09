module SearchForm
  module Filters
    # Renders a select field for filtering by the number of associated answers
    # of questions for quizzes.
    # This component has a special behavior based on the `purpose` parameter:
    # it will not render itself at all if the purpose is "import", making it
    # suitable for contexts where this filter is not applicable.
    class AnswerCountFilter < ViewComponent::Base
      attr_accessor :form_state
      attr_reader :purpose

      # Initializes the AnswerCountFilter.
      #
      # This component is specialized and does not accept most standard field
      # options. Instead, it hard-codes its own options for the underlying
      # `SelectField`.
      #
      # @param form_state [SearchForm::FormState] The form state object.
      # @param purpose [String] The context in which the form is used.
      #   Defaults to `"media"`. If set to `"import"`, the component will
      #   not be rendered.
      # @param options [Hash] Additional options passed to the select field.
      def initialize(form_state:, purpose: "media", **options)
        super()
        @form_state = form_state
        @purpose = purpose
        @options = options
      end

      delegate :form, to: :form_state

      def with_form(form)
        form_state.with_form(form)
        self
      end

      # Conditionally renders the component. It will not render if the purpose
      # is "import".
      #
      # @return [Boolean] `false` if the purpose is "import", otherwise `true`.
      def render?
        purpose != "import"
      end

      def before_render
        setup_fields if render?
      end

      private

        def setup_fields
          @select_field = Fields::SelectField.new(
            name: :answers_count,
            label: I18n.t("basics.answer_count"),
            help_text: I18n.t("search.filters.helpdesks.answer_count_filter"),
            collection: [
              [I18n.t("access.irrelevant"), "irrelevant"],
              [1, 1],
              [2, 2],
              [3, 3],
              [4, 4],
              [5, 5],
              [6, 6],
              [">6", 7]
            ],
            selected: "irrelevant",
            form_state: form_state,
            **@options
          ).with_form(form)
        end
    end
  end
end
