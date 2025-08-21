module SearchForm
  module Builders
    class RadioGroupBuilder
      def initialize(form_state, name)
        @form_state = form_state
        @name = name
        @buttons = []
      end

      def add_button(value:, label:, checked: false, disabled: true, inline: true)
        @buttons << {
          value: value,
          label: label,
          checked: checked,
          disabled: disabled,
          inline: inline
        }
        self
      end

      def build_radio_group
        radio_group = Controls::RadioGroup.new(
          form_state: @form_state,
          name: @name
        )

        @buttons.each do |button|
          radio_group.with_radio_button(
            form_state: @form_state,
            name: @name,
            value: button[:value],
            label: button[:label],
            checked: button[:checked],
            disabled: button[:disabled],
            inline: button[:inline]
          )
        end

        radio_group
      end

      # Factory methods for common radio group types
      def self.operator_radios(form_state, or_checked: true, disabled: true, inline: true)
        new(form_state, :tag_operator)
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

      def self.inheritance_radios(form_state, with_inheritance_checked: true, disabled: true,
                                  inline: true)
        new(form_state, :teachable_inheritance)
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
