module SearchForm
  module Filters
    class TeachableFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :teachable_ids,
          label: I18n.t("basics.associated_to"),
          help_text: I18n.t("admin.medium.info.search_teachable"),
          collection: [], # Will be populated by grouped_teachable_list_alternative later
          **
        )

        @options.reverse_merge!(
          multiple: true,
          class: "selectize",
          disabled: true,
          required: true,
          prompt: I18n.t("basics.select")
        )

        @show_radio_group = false
      end

      def with_inheritance_radios
        @show_radio_group = true
        self
      end

      def show_radio_group?
        @show_radio_group
      end

      def render_radio_group
        return unless show_radio_group?

        builder = Builders::RadioGroupFactories::InheritanceRadios.build(form_state)
        render(builder.build_radio_group)
      end

      # Override to provide custom data attributes for the "all_teachables" checkbox
      def all_toggle_data_attributes
        {
          search_form_target: "allToggle",
          action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
          toggle_radio_group: "teachable_inheritance",
          default_radio_value: "1" # Select "with_inheritance" by default
        }
      end

      # Load grouped collection just in time (helpers available now)
      def before_render
        super
        @collection = helpers.grouped_teachable_list_alternative
      end
    end
  end
end
