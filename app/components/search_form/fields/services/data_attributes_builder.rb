module SearchForm
  module Fields
    module Services
      # Data attributes builder service for Stimulus integration
      #
      # This service object constructs HTML data attributes needed for
      # Stimulus controller integration and JavaScript behaviors. It
      # handles different types of form controls and their specific
      # data attribute requirements.
      #
      # Features:
      # - Stimulus target and action attribute generation
      # - Field-specific data attribute handling
      # - Integration with search form Stimulus controllers
      # - Support for toggle behaviors and form interactions
      # - Merging of base and custom data attributes
      #
      # @example Service usage
      #   data_builder = DataAttributesBuilder.new(field)
      #   data_builder.select_data_attributes
      #   # => { search_form_target: "select", custom_option: "value" }
      #
      # @example Checkbox data attributes
      #   data_builder.checkbox_data_attributes
      #   # => { search_form_target: "allToggle", action: "change->search-form#toggleFromCheckbox" }
      #
      # The service ensures consistent data attribute patterns across
      # all form fields for reliable JavaScript behavior.
      class DataAttributesBuilder
        def initialize(field)
          @field = field
        end

        def select_data_attributes
          base_data = @field.options[:data] || {}
          base_data.merge(search_form_target: "select")
        end

        def checkbox_data_attributes
          if @field.respond_to?(:all_toggle_data_attributes)
            @field.all_toggle_data_attributes
          else
            {
              search_form_target: "allToggle",
              action: "change->search-form#toggleFromCheckbox"
            }
          end
        end
      end
    end
  end
end
