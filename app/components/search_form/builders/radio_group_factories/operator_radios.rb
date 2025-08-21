module SearchForm
  module Builders
    module RadioGroupFactories
      class OperatorRadios < Base
        def self.build(form_state, or_checked: true, disabled: true, inline: true)
          create_builder(form_state, :tag_operator)
            .add_button(
              value: "or",
              label: I18n.t("basics.OR"),
              checked: or_checked,
              disabled: disabled,
              inline: inline
            )
            .add_button(
              value: "and",
              label: I18n.t("basics.AND"),
              checked: !or_checked,
              disabled: disabled,
              inline: inline
            )
        end
      end
    end
  end
end
