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
    end
  end
end
