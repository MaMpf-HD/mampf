module SearchForm
  module Builders
    class FormBuilder
      def initialize(form_state)
        @form_state = form_state
        @fields = []
        @hidden_fields = []
      end

      def tag_filter(&)
        # Use the TagFilterBuilder instead of the filter directly
        builder = TagFilterBuilder.new(@form_state)

        # If a block is given, yield the builder to configure it
        yield(builder) if block_given?

        # Build the filter and add it to fields
        filter = builder.build
        @fields << filter
        filter  # Return the filter
      end

      def medium_type_filter(purpose: "media", &block)
        filter = Filters::MediumTypeFilter.new(purpose: purpose)
        filter.form_state = @form_state
        @fields << filter
        filter  # Return the filter
      end

      def fulltext_filter
        filter = Filters::FulltextFilter.new
        filter.form_state = @form_state
        @fields << filter
        filter  # Return the filter
      end

      def hidden_field(name, value)
        @hidden_fields << { name: name, value: value }
        self
      end

      def build_form(url:, **form_options)
        SearchForm.new(url: url, **form_options).tap do |form|
          @fields.each { |field| form.with_field(field) }
          @hidden_fields.each { |hf| form.with_hidden_field(name: hf[:name], value: hf[:value]) }
        end
      end
    end
  end
end
