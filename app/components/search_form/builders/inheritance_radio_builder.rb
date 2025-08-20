module SearchForm
  module Builders
    class InheritanceRadioBuilder
      def initialize(form_state)
        @form_state = form_state
      end

      def build_radio_group(with_inheritance_checked: true, disabled: true, inline: true)
        radio_group = Controls::RadioGroup.new(
          form_state: @form_state,
          name: :teachable_inheritance
        )

        # Add radio buttons to the group after instantiation
        radio_group.with_radio_button(
          form_state: @form_state,
          name: :teachable_inheritance,
          value: "1",
          label: I18n.t("basics.with_inheritance"),
          checked: with_inheritance_checked,
          disabled: disabled,
          inline: inline
        )

        radio_group.with_radio_button(
          form_state: @form_state,
          name: :teachable_inheritance,
          value: "0",
          label: I18n.t("basics.without_inheritance"),
          checked: !with_inheritance_checked,
          disabled: disabled,
          inline: inline
        )

        radio_group
      end
    end
  end
end
