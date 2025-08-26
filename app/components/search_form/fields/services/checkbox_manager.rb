module SearchForm
  module Fields
    module Services
      # Manages the creation and state of the "All" checkbox associated with a
      # `MultiSelectField`. It is responsible for populating the field's `checkbox`
      # slot with a default checkbox component if one is not provided manually.
      class CheckboxManager
        # Initializes a new CheckboxManager.
        #
        # @param field [SearchForm::Fields::MultiSelectField] The field component
        # that this manager serves.
        def initialize(field)
          @field = field
          @data_builder = DataAttributesBuilder.new(field)
        end

        # Creates a default "All" checkbox and populates the field's `checkbox` slot
        # with it. This method is typically called from the field's `before_render` hook.
        # The checkbox is configured to be checked by default and includes the necessary
        # Stimulus data attributes for toggling the select input.
        def setup_default_checkbox
          @field.with_checkbox(
            form_state: @field.form_state,
            name: @field.all_toggle_name,
            label: @field.all_checkbox_label,
            checked: true,
            data: @data_builder.checkbox_data_attributes
          )
        end

        # Determines whether the checkbox should be rendered in the field's template.
        #
        # @return [Boolean] `true` if the field's `checkbox` slot has been populated,
        #   either manually or by `setup_default_checkbox`.
        def should_show_checkbox?
          @field.checkbox.present?
        end
      end
    end
  end
end
