module SearchForm
  module Filters
    # Renders a multi-select field for filtering by tags. This is a complex
    # component that extends `MultiSelectField` with several key features:
    # - The tag collection is loaded dynamically via an AJAX request.
    # - It can optionally display an "AND/OR" radio button group to control
    #   the search logic.
    # - It provides custom data attributes for the "All" checkbox to interact
    #   with the radio button group.
    class TagFilter < Fields::MultiSelectField
      # Initializes the TagFilter.
      #
      # The component is initialized with an empty collection, as the tags are
      # intended to be fetched via an AJAX call handled by JavaScript. It merges
      # a set of `data` attributes into the field's options to configure the
      # AJAX behavior.
      #
      # @param ** [Hash] Catches any other keyword arguments, which are passed
      #   to the superclass.
      def initialize(**)
        # Pass empty array for collection - tags will be loaded by AJAX
        super(
          name: :tag_ids,
          label: I18n.t("basics.tags"),
          help_text: I18n.t("admin.medium.info.search_tags"),
          collection: [],
          **
        )

        # Add AJAX-specific options
        @options.reverse_merge!(
          data: {
            filled: false,
            ajax: true,
            model: "tag",
            locale: I18n.locale,
            placeholder: I18n.t("basics.select"),
            no_results: I18n.t("basics.no_results")
          }
        )

        @show_radio_group = false
      end

      # A configuration method to enable the rendering of the "AND/OR" operator
      # radio button group.
      #
      # @return [self] Returns the component instance to allow for method chaining.
      def with_operator_radios
        @show_radio_group = true
        self
      end

      # A hook for the parent template to determine if the radio button group
      # should be rendered.
      #
      # @return [Boolean] `true` if the radio group has been enabled.
      def show_radio_group?
        @show_radio_group
      end

      # Implements the parent's `render_radio_group` hook to render the
      # "AND/OR" radio buttons using the `Controls::RadioGroup` component.
      #
      # @return [String, nil] The rendered HTML for the radio group, or `nil`.
      def render_radio_group
        return unless show_radio_group?

        render(Controls::RadioGroup.new(
                 form_state: form_state,
                 name: :tag_operator
               )) do |group|
          group.add_radio_button(
            value: "or",
            label: I18n.t("basics.OR"),
            checked: true,  # or_checked default from OperatorRadios
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
          group.add_radio_button(
            value: "and",
            label: I18n.t("basics.AND"),
            checked: false, # !or_checked
            disabled: true,
            inline: true,
            stimulus: { radio_toggle: true, controls_select: false }
          )
        end
      end

      # Overrides a hook from the `DataAttributesBuilder` to provide custom
      # `data` attributes for the "All" checkbox. These attributes are used by
      # the Stimulus controller to show/hide and enable/disable the "AND/OR"
      # radio group when the "All" checkbox is toggled.
      #
      # @return [Hash] A hash of data attributes.
      def all_toggle_data_attributes
        {
          search_form_target: "allToggle",
          action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
          toggle_radio_group: "tag_operator",
          default_radio_value: "or"
        }
      end
    end
  end
end
