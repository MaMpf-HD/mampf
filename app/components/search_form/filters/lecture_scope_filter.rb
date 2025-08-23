module SearchForm
  module Filters
    class LectureScopeFilter < Fields::MultiSelectField
      def initialize(**)
        super(
          name: :lectures,
          label: I18n.t("basics.lectures"),
          help_text: I18n.t("search.media.lectures"),
          collection: Lecture.select,
          **
        )

        @show_radio_group = false
      end

      def with_lecture_options
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
                 name: :lecture_option
               )) do |group|
          group.add_radio_button(
            value: "0",
            label: I18n.t("search.media.lecture_options.all"),
            checked: true,
            disabled: false,
            inline: false,
            stimulus: { radio_toggle: true, controls_select: false }
          )
          group.add_radio_button(
            value: "1",
            label: I18n.t("search.media.lecture_options.subscribed"),
            checked: false,
            disabled: false,
            inline: false,
            stimulus: { radio_toggle: true, controls_select: false }
          )
          group.add_radio_button(
            value: "2",
            label: I18n.t("search.media.lecture_options.own_selection"),
            checked: false,
            disabled: false,
            inline: false,
            stimulus: { radio_toggle: true, controls_select: true }
          )
        end
      end

      # We don't want the all checkbox for this component
      def show_checkbox?
        false
      end
    end
  end
end
