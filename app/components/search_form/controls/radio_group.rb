module SearchForm
  module Controls
    class RadioGroup < BaseControl
      attr_reader :name

      renders_many :radio_buttons, "SearchForm::Controls::RadioButton"

      def initialize(form_state:, name:, **)
        super(form_state: form_state, **)
        @name = name
      end

      # Helper method with auto-injection of form_state and name
      def add_radio_button(**, &)
        with_radio_button(
          form_state: form_state,
          name: name,
          **,
          &
        )
      end

      def default_container_class
        "mt-2"
      end

      private

        # RadioGroup uses just the name for its ID
        def id_parts
          [name]
        end
    end
  end
end
