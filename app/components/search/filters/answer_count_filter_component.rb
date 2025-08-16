module Search
  module Filters
    class AnswerCountFilterComponent < Search::SelectComponent
      def initialize(purpose: "media", context: "media", **options)
        # Skip initialization for import purpose - component won't render
        return if purpose == "import"

        super(
          name: :answers_count,
          label: I18n.t("basics.answer_count"),
          help_text: I18n.t("admin.medium.info.answer_count"),
          column_class: "col-6 col-lg-3",
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
          context: context,
          **options.reverse_merge(
            selected: "irrelevant",
            class: "form-select"
          )
        )
      end

      # Override call to conditionally render based on purpose
      def call
        return nil if @purpose == "import"

        super
      end

      private

        attr_reader :purpose
    end
  end
end
