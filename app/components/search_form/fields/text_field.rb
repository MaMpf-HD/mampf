# app/components/search_form/fields/text_field.rb
module SearchForm
  module Fields
    class TextField < Field
      def initialize(name:, label:, column_class: "col-4", **)
        super
      end

      # HTML options for the text field
      def text_field_html_options
        options.merge(id: element_id)
      end

      # Whether to show help text
      def show_help_text?
        help_text.present?
      end

      # Whether to show additional content
      def show_content?
        content.present?
      end

      protected

        def process_options(options)
          options.reverse_merge(class: "form-control")
        end
    end
  end
end
