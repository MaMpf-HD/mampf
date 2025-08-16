module Search
  module Filters
    class TeachableFilterComponent < Search::MultiSelectComponent
      def initialize(context: "media", **)
        super(
          name: :teachable_ids,
          label: I18n.t("basics.associated_to"),
          help_text: I18n.t("admin.medium.info.search_teachable"),
          collection: [], # Will be populated by grouped_teachable_list_alternative
          all_toggle_name: :all_teachables,
          column_class: "col-6 col-lg-3",
          context: context,
          **
        )

        # These options match exactly what's in the partial
        options.reverse_merge!(
          multiple: true,
          class: "selectize",
          disabled: true,
          required: true,
          prompt: I18n.t("basics.select")
        )
      end

      # Method to render the teachable inheritance radio buttons
      def render_inheritance_radios
        content_tag(:div) do
          safe_join([
                      content_tag(:div, class: "form-check form-check-inline") do
                        form.radio_button(:teachable_inheritance, "1",
                                          checked: true,
                                          class: "form-check-input") +
                        form.label(:teachable_inheritance,
                                   I18n.t("basics.with_inheritance"),
                                   value: "1",
                                   class: "form-check-label")
                      end,
                      content_tag(:div, class: "form-check form-check-inline") do
                        form.radio_button(:teachable_inheritance, "0",
                                          class: "form-check-input") +
                        form.label(:teachable_inheritance,
                                   I18n.t("basics.without_inheritance"),
                                   value: "0",
                                   class: "form-check-label")
                      end
                    ])
        end
      end
    end
  end
end
