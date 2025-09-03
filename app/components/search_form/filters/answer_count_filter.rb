module SearchForm
  module Filters
    # Renders a select field for filtering by the number of associated answers
    # of questions for quizzes.
    # This component has a special behavior based on the `purpose` parameter:
    # it will not render itself at all if the purpose is "import", making it
    # suitable for contexts where this filter is not applicable.
    class AnswerCountFilter < Fields::SelectField
      # Initializes the AnswerCountFilter.
      #
      # This component is specialized and does not accept most standard field
      # options. Instead, it hard-codes its own `:name`, `:label`, `:collection`,
      # and other `SelectField` options.
      #
      # @param purpose [String] The context in which the form is used.
      #   Defaults to `"media"`. If set to `"import"`, the component will
      #   not be rendered.
      # @param ** [Hash] Catches any other keyword arguments, which are ignored.
      def initialize(purpose: "media", **)
        @purpose = purpose

        # Always call super to ensure the object is fully initialized
        super(
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
          **
          )
      end

      # Conditionally renders the component. It will not render if the purpose
      # is "import".
      #
      # @return [Boolean] `false` if the purpose is "import", otherwise `true`.
      def render?
        purpose != "import"
      end

      private

        attr_reader :purpose
    end
  end
end
