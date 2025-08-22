module SearchForm
  module Fields
    module Services
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
