module SearchForm
  module Filters
    class TagsFilterComponent < SearchForm::MultiSelectComponent
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
          action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
          toggle_radio_group: "tag_operator",
          default_radio_value: "or"
        }
      end

      # Method to render the tag operators using our RadioGroup
      def render_tag_operator_radios
        render(SearchForm::Controls::RadioGroup.new(
                 form: form,
                 name: :tag_operator
               )) do |group|
          group.with_radio_button(
            form: form,
            name: :tag_operator,
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,
            disabled: true,
            inline: true
          )

          group.with_radio_button(
            form: form,
            name: :tag_operator,
            value: "and",
            label: I18n.t("basics.AND"),
            disabled: true,
            inline: true
          )
        end
      end
    end
  end
end
