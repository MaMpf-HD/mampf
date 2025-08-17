module Search
  module Filters
    class TagsFilterComponent < Search::MultiSelectComponent
      def initialize(context: "media", **)
        # Pass empty array for collection - tags will be loaded by AJAX
        super(
          name: :tag_ids,
          label: I18n.t("basics.tags"),
          help_text: I18n.t("admin.medium.info.search_tags"),
          collection: [],
          all_toggle_name: :all_tags,
          context: context,
          **
        )

        # Add AJAX-specific options
        options.reverse_merge!(
          multiple: true,
          data: {
            filled: false,
            ajax: true,
            model: "tag",
            locale: I18n.locale,
            no_results: I18n.t("basics.no_results")
          }
        )
      end

      # Override to provide custom data attributes for the "all_tags" checkbox
      def all_toggle_data_attributes
        {
          search_form_target: "allToggle",
          action: "change->search-form#toggleFromCheckbox change->search-form#toggleTagOperators"
        }
      end

      # Method to render the radio buttons, called from the template
      def render_tag_operator_radios
        content_tag(:div, class: "mt-2") do
          safe_join([
                      content_tag(:div, class: "form-check form-check-inline") do
                        form.radio_button(:tag_operator, "or",
                                          checked: true,
                                          class: "form-check-input",
                                          disabled: true,
                                          data: { tag_operator: "or" }) +
                        form.label(:tag_operator, I18n.t("basics.OR"),
                                   value: "or",
                                   class: "form-check-label")
                      end,
                      content_tag(:div, class: "form-check form-check-inline") do
                        form.radio_button(:tag_operator, "and",
                                          class: "form-check-input",
                                          disabled: true,
                                          data: { tag_operator: "and" }) +
                        form.label(:tag_operator, I18n.t("basics.AND"),
                                   value: "and",
                                   class: "form-check-label")
                      end
                    ])
        end
      end
    end
  end
end
