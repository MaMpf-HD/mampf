module SearchForm
  module Filters
    class TagFilter < Fields::MultiSelectField
      def initialize(**)
        # Pass empty array for collection - tags will be loaded by AJAX
        super(
          name: :tag_ids,
          label: I18n.t("basics.tags"),
          help_text: I18n.t("admin.medium.info.search_tags"),
          collection: [],
          **
        )

        # Add AJAX-specific options
        @options.reverse_merge!(
          data: {
            filled: false,
            ajax: true,
            model: "tag",
            locale: I18n.locale,
            placeholder: I18n.t("basics.select"),
            no_results: I18n.t("basics.no_results")
          }
        )

        @show_radio_group = false
      end

      def with_operator_radios
        @show_radio_group = true
        self
      end

      def show_radio_group?
        @show_radio_group
      end

      def render_radio_group
        return unless show_radio_group?

        render(Controls::RadioGroup.new(
                 form_state: form_state,
                 name: :tag_operator
               )) do |group|
          group.with_radio_button(
            form_state: form_state,
            name: :tag_operator,
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,  # or_checked default from OperatorRadios
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
          group.with_radio_button(
            form_state: form_state,
            name: :tag_operator,
            value: "and",
            label: I18n.t("basics.AND"),
            checked: false, # !or_checked
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
        end
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
    end
  end
end
