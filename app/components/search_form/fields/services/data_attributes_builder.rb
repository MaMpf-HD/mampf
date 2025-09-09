module SearchForm
  module Fields
    module Services
      # A service class responsible for assembling the final `data` attribute hash
      # for a field's HTML elements. It combines custom data attributes provided
      # in the field's options with the specific `data` attributes required for
      # Stimulus controllers (e.g., targets and actions).
      class DataAttributesBuilder
        # Initializes a new DataAttributesBuilder.
        #
        # @param field_data [SearchForm::Fields::FieldData] The field data object
        # that this manager serves.
        def initialize(field_data)
          @field_data = field_data
        end

        # Builds the data attributes for the `<select>` element of a `MultiSelectField`.
        # It merges a default `search_form_target: "select"` with any custom `data`
        # attributes provided in the field's options.
        #
        # @return [Hash] The final data attributes hash for the select element.
        def select_data_attributes
          base_data = @field_data.options[:data] || {}
          base_data.merge(search_form_target: "select")
        end

        # Builds the data attributes for the "All" checkbox of a `MultiSelectField`.
        # It provides the necessary Stimulus target and action for the checkbox functionality.
        #
        # @return [Hash] The final data attributes hash for the checkbox.
        def checkbox_data_attributes
          {
            search_form_target: "allToggle",
            action: "change->search-form#toggleFromCheckbox"
          }
        end
      end
    end
  end
end
