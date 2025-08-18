module SearchForm
  module Filters
    class AccessFilterComponent < SearchForm::SelectComponent
      def initialize(context: "media", **options)
        super(
          name: :access,
          label: I18n.t("basics.access_rights"), # Not 'basics.access'
          column_class: "col-6 col-lg-3",
          collection: [
            [I18n.t("access.irrelevant"), "irrelevant"],
            [I18n.t("access.all"), "all"],
            [I18n.t("access.users"), "users"],
            [I18n.t("access.subscribers"), "subscribers"],
            [I18n.t("access.locked"), "locked"],
            [I18n.t("access.unpublished"), "unpublished"]
          ],
          context: context,
          **options.reverse_merge(class: "form-select")
        )

        # Set the default selected value
        @options[:selected] = "irrelevant" unless options.key?(:selected)
      end
    end
  end
end
