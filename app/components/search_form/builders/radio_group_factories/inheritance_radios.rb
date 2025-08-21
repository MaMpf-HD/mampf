module SearchForm
  module Builders
    module RadioGroupFactories
      class InheritanceRadios < Base
        def self.build(form_state, with_inheritance_checked: true, disabled: true, inline: true)
          create_builder(form_state, :teachable_inheritance)
            .add_button(
              value: "1",
              label: I18n.t("basics.with_inheritance"),
              checked: with_inheritance_checked,
              disabled: disabled,
              inline: inline
            )
            .add_button(
              value: "0",
              label: I18n.t("basics.without_inheritance"),
              checked: !with_inheritance_checked,
              disabled: disabled,
              inline: inline
            )
        end
      end
    end
  end
end
