module SearchForm
  module Fields
    module Services
      # Checkbox management service for multi-select fields
      #
      # This service object handles the creation and configuration of
      # "All" toggle checkboxes for multi-select fields. It manages
      # the checkbox setup, labeling, and data attributes needed for
      # JavaScript toggle functionality.
      #
      # Features:
      # - Automatic "All" checkbox creation for multi-select fields
      # - Integration with data attributes for Stimulus behaviors
      # - Checkbox state management (checked/unchecked)
      # - Label generation and internationalization support
      # - Conditional checkbox display logic
      #
      # @example Service usage
      #   checkbox_manager = CheckboxManager.new(multi_select_field)
      #   checkbox_manager.setup_default_checkbox
      #   checkbox_manager.should_show_checkbox?
      #   # => true
      #
      # The service works with DataAttributesBuilder to provide
      # complete checkbox functionality for multi-select scenarios.
      class CheckboxManager
        def initialize(field)
          @field = field
          @data_builder = DataAttributesBuilder.new(field)
        end

        def setup_default_checkbox
          @field.with_checkbox(
            form_state: @field.form_state,
            name: @field.all_toggle_name,
            label: @field.all_checkbox_label,
            checked: true,
            data: @data_builder.checkbox_data_attributes
          )
        end

        def should_show_checkbox?
          @field.checkbox.present?
        end
      end
    end
  end
end
