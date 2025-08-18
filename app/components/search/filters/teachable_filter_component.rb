module Search
  module Filters
    class TeachableFilterComponent < Search::MultiSelectComponent
      def initialize(context: "media", **)
        super(
          name: :teachable_ids,
          label: I18n.t("basics.associated_to"),
          help_text: I18n.t("admin.medium.info.search_teachable"),
          collection: [], # Will be populated by grouped_teachable_list_alternative later
          all_toggle_name: :all_teachables,
          column_class: "col-6 col-lg-3",
          context: context,
          **
        )

        options.reverse_merge!(
          multiple: true,
          class: "selectize",
          disabled: true,
          required: true,
          prompt: I18n.t("basics.select")
        )
      end

      # Load grouped collection just in time (helpers available now)
      def before_render
        super
        @collection = helpers.grouped_teachable_list_alternative
      end

      # Method to render the teachable inheritance radio buttons using RadioGroupComponent
      def render_inheritance_radios
        render(Search::Controls::RadioGroupComponent.new(
                 form: form,
                 name: :teachable_inheritance
               )) do |group|
          group.with_radio_button(
            form: form,
            name: :teachable_inheritance,
            value: "1",
            label: I18n.t("basics.with_inheritance"),
            checked: true,
            inline: true
          )

          group.with_radio_button(
            form: form,
            name: :teachable_inheritance,
            value: "0",
            label: I18n.t("basics.without_inheritance"),
            inline: true
          )
        end
      end
    end
  end
end
