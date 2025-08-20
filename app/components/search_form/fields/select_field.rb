# app/components/search_form/fields/select_field.rb
module SearchForm
  module Fields
    class SelectField < Field
      attr_reader :collection

      def initialize(name:, label:, collection:, column_class: "col-2", **)
        @collection = collection
        super(name: name, label: label, column_class: column_class, **)
      end

      # HTML options for the select tag
      def select_html_options
        html_options_with_id
      end

      # Options hash for the select tag (the second parameter to form.select)
      def select_tag_options
        {}
      end

      protected

        def process_options(options)
          options.reverse_merge(class: "form-select")
        end
    end
  end
end
