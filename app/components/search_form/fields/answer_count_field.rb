module SearchForm
  module Fields
    # Renders a select field for filtering by the number of associated answers
    # for quiz questions. This component provides predefined answer count ranges
    # and has conditional rendering based on the form's purpose.
    #
    # The field offers options from "irrelevant" (no filtering) through specific
    # counts (1-6) and a ">6" option for questions with many answers. It will
    # not render at all when the purpose is "import", making it suitable for
    # contexts where answer count filtering is not applicable.
    #
    # @example Basic usage for media search
    #   AnswerCountField.new(form_state: form_state)
    #
    # @example Usage with import context (will not render)
    #   AnswerCountField.new(form_state: form_state, purpose: "import")
    class AnswerCountField < ViewComponent::Base
      include Mixin::FieldSetupMixin

      attr_reader :purpose, :options

      # Initializes a new AnswerCountField component.
      #
      # @param form_state [SearchForm::FormState] The form state object for context
      # @param purpose [String] The context in which the form is used (default: "media")
      # @param options [Hash] Additional options passed to the underlying select field
      def initialize(form_state:, purpose: "media", **options)
        super()
        @form_state = form_state
        @purpose = purpose
        @options = options
      end

      # Determines whether this component should be rendered.
      #
      # @return [Boolean] false if purpose is "import", true otherwise
      def render?
        purpose != "import"
      end

      private

        def setup_fields
          @select_field = create_select_field(
            name: :answers_count,
            label: I18n.t("basics.answer_count"),
            help_text: I18n.t("search.filters.helpdesks.answer_count_filter"),
            collection: build_answer_count_collection,
            selected: "irrelevant",
            **options
          )
        end

        def build_answer_count_collection
          [
            [I18n.t("access.irrelevant"), "irrelevant"],
            [1, 1],
            [2, 2],
            [3, 3],
            [4, 4],
            [5, 5],
            [6, 6],
            [">6", 7]
          ]
        end
    end
  end
end
