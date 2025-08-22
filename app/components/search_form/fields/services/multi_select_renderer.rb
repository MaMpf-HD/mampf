module SearchForm
  module Fields
    module Services
      class MultiSelectRenderer
        def initialize(field)
          @field = field
        end

        def options_html
          if grouped_collection?
            helpers.grouped_options_for_select(@field.collection, @field.selected_value)
          else
            helpers.options_for_select(@field.collection, @field.selected_value)
          end
        end

        def grouped_collection?
          return false if @field.collection.empty?

          first = @field.collection.first
          first.is_a?(Array) &&
            first.last.is_a?(Array) &&
            first.last.first.is_a?(Array)
        end

        private

          def helpers
            @field.helpers
          end
      end
    end
  end
end
