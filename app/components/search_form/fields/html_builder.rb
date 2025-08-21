module SearchForm
  module Fields
    class HtmlBuilder
      def initialize(field)
        @field = field
      end

      # Common method for building HTML options with ID
      def html_options_with_id(additional_options = {})
        @field.options.merge(id: element_id).merge(additional_options)
      end

      # Common method for building HTML options with field CSS classes
      def field_html_options(additional_options = {})
        default_options = { class: css_manager.field_css_classes }
        html_options_with_id(default_options.merge(additional_options))
      end

      # Generate a unique ID using form_state
      def element_id
        @field.form_state&.element_id_for(@field.name)
      end

      # Public ID for the <label for="..."> attribute
      def label_for
        @field.form_state&.label_for(@field.name)
      end

      private

        attr_reader :field

        def css_manager
          @css_manager ||= CssManager.new(@field)
        end
    end
  end
end
