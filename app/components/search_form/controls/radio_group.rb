module SearchForm
  module Controls
    # RadioGroup is a container component that groups multiple `RadioButton` controls.
    # Its primary responsibility is to ensure that all contained radio buttons
    # share the same `name` attribute, which is essential for them to function
    # as a single selection group.
    #
    # It provides a convenient `add_radio_button` helper to simplify the process
    # of adding buttons to the group.
    #
    # @example
    #   radio_group = RadioGroup.new(form_state: fs, name: :operator)
    #   radio_group.add_radio_button(value: "AND", label: "And", checked: true)
    #   radio_group.add_radio_button(value: "OR", label: "Or")
    #
    #   render(radio_group)
    class RadioGroup < BaseControl
      attr_reader :name

      # Defines the collection of radio buttons that this group will render.
      # ViewComponent will manage this collection.
      renders_many :radio_buttons, "SearchForm::Controls::RadioButton"

      # Initializes a new RadioGroup instance.
      #
      # @param form_state [SearchForm::Services::FormState] The shared form state object.
      # @param name [Symbol] The shared name for all radio buttons within this group.
      # @param ** [Hash] Additional options passed to the `BaseControl` initializer.
      def initialize(form_state:, name:, **)
        super(form_state: form_state, **)
        @name = name
      end

      # A helper method for adding a `RadioButton` to the group.
      # This method automatically injects the group's `form_state` and `name`
      # into the new radio button, simplifying the API for the caller.
      #
      # @param ** [Hash] All other keyword arguments are passed directly to the
      #   `RadioButton` initializer (e.g., `value:`, `label:`, `checked:`).
      # @param & [Proc] An optional block passed to the `RadioButton`.
      # @return [void]
      def add_radio_button(**, &)
        with_radio_button(
          form_state: form_state,
          name: name,
          **,
          &
        )
      end

      # Overrides the base method to provide a specific default CSS class
      # for the group's wrapping container.
      #
      # @return [String] The default CSS class.
      def default_container_class
        "mt-2"
      end

      private

        # Implements the abstract method from `BaseControl`.
        # The RadioGroup itself uses just its `name` for its ID parts, which
        # could be used to identify the wrapping `div`.
        def id_parts
          [name]
        end
    end
  end
end
