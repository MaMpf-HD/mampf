# app/components/search_form/filters/medium_access_filter.rb
module SearchForm
  module Filters
    class MediumAccessFilter < Fields::SelectField
      def initialize(**)
        super(
          name: :access,
          label: I18n.t("basics.access_rights"), # Not 'basics.access'
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
