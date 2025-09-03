module SearchForm
  module Filters
    # Renders a select field for filtering by medium access rights.
    # This component is a simple specialization of `SelectField`, pre-configured
    # with a specific name, label, and a static collection of access levels
    # (e.g., "All", "Users", "Subscribers").
    class MediumAccessFilter < Fields::SelectField
      # Initializes the MediumAccessFilter.
      #
      # This component is specialized and hard-codes its own options for the
      # underlying `SelectField`.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass (`SelectField`). This can be used to pass options like
      #   `:container_class`.
      def initialize(**)
        super(
          name: :access,
          label: I18n.t("basics.access_rights"),
          help_text: I18n.t("search.filters.helpdesks.medium_access_filter"),
          collection: [
            [I18n.t("access.irrelevant"), "irrelevant"],
            [I18n.t("access.all"), "all"],
            [I18n.t("access.users"), "users"],
            [I18n.t("access.subscribers"), "subscribers"],
            [I18n.t("access.locked"), "locked"],
            [I18n.t("access.unpublished"), "unpublished"]
          ],
          selected: "irrelevant",
          **
        )
      end
    end
  end
end
