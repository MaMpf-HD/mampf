# app/components/search_form/filters/teachable_filter.rb
module SearchForm
  module Filters
    class TeachableFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :teachable_ids,
          label: I18n.t("basics.associated_to"),
          help_text: I18n.t("admin.medium.info.search_teachable"),
          collection: [], # Will be populated by grouped_teachable_list_alternative later
          all_toggle_name: :all_teachables,
          column_class: "col-6 col-lg-3",
          **
        )

        @options.reverse_merge!(
          multiple: true,
          class: "selectize",
          disabled: true,
          required: true,
          prompt: I18n.t("basics.select")
        )
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

      # Method to render the teachable inheritance radio buttons using RadioGroup
      def render_inheritance_radios
        render(Controls::RadioGroup.new(
                 form_state: form_state,
                 name: :teachable_inheritance
               )) do |group|
          group.with_radio_button(
            form_state: form_state,
            name: :teachable_inheritance,
            value: "1",
            label: I18n.t("basics.with_inheritance"),
            checked: true,
            disabled: true,
            inline: true
          )

          group.with_radio_button(
            form_state: form_state,
            name: :teachable_inheritance,
            value: "0",
            label: I18n.t("basics.without_inheritance"),
            disabled: true,
            inline: true
          )
        end
      end
    end
  end
end
