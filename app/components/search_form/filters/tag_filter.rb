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

        @show_radio_group = false
      end

      def configure_ajax(model: "tag", locale: nil, no_results: nil)
        locale ||= I18n.locale
        no_results ||= I18n.t("basics.no_results")

        @options[:data].merge!(
          model: model,
          locale: locale,
          no_results: no_results
        )
        self
      end

      def with_operator_radios
        @show_radio_group = true
        self
      end

      def show_radio_group?
        @show_radio_group
      end

      # In TagFilter
      def render_radio_group
        return unless show_radio_group?

        builder = Builders::RadioGroupFactories::OperatorRadios.build(form_state)
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
