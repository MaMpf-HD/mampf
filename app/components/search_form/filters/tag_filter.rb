# app/components/search_form/filters/tag_filter.rb
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
          all_toggle_name: :all_tags,
          **
        )

        # Add AJAX-specific options
        @options.reverse_merge!(
          multiple: true,
          data: {
            filled: false,
            ajax: true,
            model: "tag",
            locale: I18n.locale,
            no_results: I18n.t("basics.no_results")
          }
        )

        @show_operator_radios = false
      end

      def with_operator_radios
        @show_operator_radios = true
        self
      end

      def show_operator_radios?
        @show_operator_radios
      end

      def render_operator_radios
        return unless show_operator_radios?

        builder = Builders::OperatorRadioBuilder.new(form_state)
        render(builder.build_radio_group)
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
