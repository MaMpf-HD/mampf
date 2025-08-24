# frozen_string_literal: true

module SearchForm
  module Filters
    # Tag filter for selecting content tags
    #
    # This filter provides a multi-select dropdown for choosing tags, with
    # AJAX-powered dynamic loading of tag options. Tags are loaded on-demand
    # to improve initial page load performance, especially when there are
    # many available tags.
    #
    # Features:
    # - Multi-select tag dropdown with AJAX loading
    # - Dynamic tag search and filtering
    # - Support for inheritance-based tag filtering
    # - Internationalized labels and help text
    # - Integration with tag model for content categorization
    #
    # @example Basic tag filter
    #   add_tag_filter
    #
    # @example Tag filter with inheritance
    #   add_tag_filter_with_inheritance
    #
    # The filter starts with an empty collection and uses AJAX to populate
    # tag options based on user input or form context.
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
          group.add_radio_button(
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,  # or_checked default from OperatorRadios
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
          group.add_radio_button(
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
