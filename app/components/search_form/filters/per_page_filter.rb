module SearchForm
  module Filters
    # Renders a select field for controlling pagination (items per page).
    # This component is a specialization of `SelectField` that allows for easy
    # configuration of the available page size options and a default value.
    class PerPageFilter < Fields::SelectField
      # Initializes the PerPageFilter.
      #
      # @param per_options [Array<Array>] An array of [text, value] pairs for the
      #   select options. Defaults to `[[10, 10], [20, 20], [50, 50]]`.
      # @param default [Object] The value that should be pre-selected in the
      #   dropdown. Defaults to `10`.
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`SelectField`).
      def initialize(per_options: [[10, 10], [20, 20], [50, 50]], default: 10, **)
        super(
          name: :per,
          label: I18n.t("basics.hits_per_page"),
          collection: per_options,
          selected: default,
          **
        )
      end
    end
  end
end
