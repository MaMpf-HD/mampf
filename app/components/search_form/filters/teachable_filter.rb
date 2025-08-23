module SearchForm
  module Filters
    class TeachableFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :teachable_ids,
          label: I18n.t("basics.associated_to"),
          help_text: I18n.t("admin.medium.info.search_teachable"),
          collection: grouped_teachable_list,
          **
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

        render(Controls::RadioGroup.new(
                 form_state: form_state,
                 name: :teachable_inheritance
               )) do |group|
          group.add_radio_button( # Changed from with_radio_button to add_radio_button
            value: "1",
            label: I18n.t("basics.with_inheritance"),
            checked: true,
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
          group.add_radio_button( # Changed from with_radio_button to add_radio_button
            value: "0",
            label: I18n.t("basics.without_inheritance"),
            checked: false,
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
        end
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

      def grouped_teachable_list
        list = []
        Course.find_each do |c|
          lectures = [["#{c.short_title} Modul", "Course-#{c.id}"]]
          c.lectures.includes(:term).find_each do |l|
            lectures.push([l.short_title, "Lecture-#{l.id}"])
          end
          list.push([c.title, lectures])
        end
        list
      end
    end
  end
end
