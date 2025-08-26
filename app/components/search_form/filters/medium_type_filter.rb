module SearchForm
  module Filters
    # Renders a multi-select field for filtering by medium type (e.g., WorkedExample",
    # "Quiz"). This component is highly contextual and dynamically alters its
    # behavior, collection, and appearance based on the `purpose` of the search
    # form and the `current_user`'s permissions.
    class MediumTypeFilter < Fields::MultiSelectField
      # Initializes the MediumTypeFilter.
      #
      # The component's behavior is determined by the `purpose` and `current_user`
      # arguments. It dynamically sets its collection, pre-selected values, and
      # HTML attributes (`multiple`, `disabled`) based on these inputs.
      #
      # @param current_user [User] The user performing the search. Their role
      #   (e.g., admin, editor) can affect the available medium types.
      # @param purpose [String] The context of the search form, which dictates
      #   the component's configuration. Can be "media", "import", or "quiz".
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass.
      def initialize(current_user:, purpose: "media", **)
        super(
          name: :types,
          label: I18n.t("basics.types"), # Plural for media
          help_text: I18n.t("search.media.type"),
          collection: media_sorts_select(current_user, purpose),
          selected: sort_preselect(purpose),
          **
        )

        @purpose = purpose
        @current_user = current_user

        # Update options based on purpose
        @options[:multiple] = purpose.in?(["media", "import"])
        @options[:disabled] = purpose == "media"
      end

      attr_reader :purpose, :current_user

      # Overrides the parent class's hook to conditionally disable the "All" checkbox.
      # The checkbox is skipped for "import" and "quiz" purposes where selecting
      # "All" types is not a valid option.
      #
      # @return [Boolean] `true` if the "All" checkbox should be skipped.
      def skip_all_checkbox?
        purpose.in?(["import", "quiz"])
      end

      private

        # Determines the pre-selected value for the select input.
        # For the "quiz" purpose, it defaults to "Question". Otherwise, it is blank.
        #
        # @param purpose [String] The context of the search form.
        # @return [String] The value to be pre-selected, or an empty string.
        def sort_preselect(purpose)
          return "" unless purpose == "quiz"

          "Question"
        end

        # Acts as a factory to generate the appropriate collection of medium types
        # based on the form's purpose and the user's role.
        #
        # @param current_user [User] The user performing the search.
        # @param purpose [String] The context of the search form.
        # @return [Array<Array>] A collection suitable for a select field.
        def media_sorts_select(current_user, purpose)
          return Medium.select_quizzables if purpose == "quiz"
          return Medium.select_importables if purpose == "import"
          return Medium.select_generic unless current_user.admin_or_editor?

          Medium.select_sorts
        end
    end
  end
end
