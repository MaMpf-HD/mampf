module SearchForm
  module Fields
    module Services
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
