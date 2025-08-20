# app/components/search_form/builders/form_builder.rb
module SearchForm
  module Builders
    class FormBuilder
      def initialize(form_state)
        @form_state = form_state
        @fields = []
        @hidden_fields = []
      end

      def tag_filter(&)
        builder = TagFilterBuilder.new(@form_state)
        yield(builder) if block_given?
        @fields << builder.build
        self
      end

      def medium_type_filter(purpose: "media", &block)
        # We'll implement MediumTypeFilterBuilder next
        filter = Filters::MediumTypeFilter.new(purpose: purpose)
        filter.form_state = @form_state
        @fields << filter
        self
      end

      def fulltext_filter
        filter = Filters::FulltextFilter.new
        filter.form_state = @form_state
        @fields << filter
        self
      end

      def hidden_field(name, value)
        @hidden_fields << { name: name, value: value }
        self
      end

      def build_form(url:, **form_options)
        form = SearchForm.new(url: url, **form_options)

        # Override the form_state in the form component
        form.instance_variable_set(:@form_state, @form_state)

        @fields.each { |field| form.with_field(field) }
        @hidden_fields.each do |field_data|
          # Pass keyword arguments directly, not a HiddenField object
          form.with_hidden_field(name: field_data[:name], value: field_data[:value])
        end

        form
      end
    end
  end
end
