module SearchForm
  module Controls
    # Radio group control component for grouped single selection
    #
    # This control manages a collection of radio buttons that share the same
    # name attribute, ensuring only one can be selected at a time. It provides
    # a convenient way to create radio button groups with automatic parameter
    # injection to reduce repetitive code.
    #
    # Features:
    # - Automatic name and form_state injection to child radio buttons
    # - ViewComponent renders_many for radio button management
    # - Consistent grouping behavior for single selection
    # - Helper method to simplify radio button creation
    # - Integration with form state for proper ID generation
    #
    # @param name [String, Symbol] The shared name for all radio buttons in the group
    #
    # @example Basic radio group
    #   radio_group = RadioGroup.new(
    #     form_state: form_state,
    #     name: :sort_order
    #   )
    #
    #   radio_group.add_radio_button(value: "asc", label: "Ascending")
    #   radio_group.add_radio_button(value: "desc", label: "Descending")
    #
    # @example Radio group with checked option
    #   radio_group.add_radio_button(
    #     value: "date",
    #     label: "Sort by Date",
    #     checked: true
    #   )
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
