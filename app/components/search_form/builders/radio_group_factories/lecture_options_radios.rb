module SearchForm
  module Builders
    module RadioGroupFactories
      class LectureOptionsRadios < Base
        def self.build(form_state, all_checked: true, disabled: false, inline: false)
          create_builder(form_state, :lecture_option)
            .add_button(
              value: "0",
              label: I18n.t("search.media.lecture_options.all"),
              checked: all_checked,
              disabled: disabled,
              inline: inline,
              stimulus: { radio_toggle: true, controls_select: false }
            )
            .add_button(
              value: "1",
              label: I18n.t("search.media.lecture_options.subscribed"),
              checked: false,
              disabled: disabled,
              inline: inline,
              stimulus: { radio_toggle: true, controls_select: false }
            )
            .add_button(
              value: "2",
              label: I18n.t("search.media.lecture_options.own_selection"),
              checked: false,
              disabled: disabled,
              inline: inline,
              stimulus: { radio_toggle: true, controls_select: true }
            )
        end
      end
    end
  end
end
