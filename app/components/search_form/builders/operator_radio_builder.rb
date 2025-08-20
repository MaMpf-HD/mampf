module SearchForm
  module Builders
    class OperatorRadioBuilder
      def initialize(form_state)
        @form_state = form_state
      end

      def build_radio_group(or_checked: true, disabled: true, inline: true)
        radio_group = Controls::RadioGroup.new(
          form_state: @form_state,
          name: :tag_operator
        )

        # Add radio buttons to the group after instantiation
        radio_group.with_radio_button(
          form_state: @form_state,
          name: :tag_operator,
          value: "or",
          label: I18n.t("basics.OR"),
          checked: or_checked,
          disabled: disabled,
          inline: inline
        )

        radio_group.with_radio_button(
          form_state: @form_state,
          name: :tag_operator,
          value: "and",
          label: I18n.t("basics.AND"),
          checked: !or_checked,
          disabled: disabled,
          inline: inline
        )

        radio_group
      end
    end
  end
end
