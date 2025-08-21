module SearchForm
  module Builders
    class FormBuilder
      def initialize(form_state)
        @form_state = form_state
        @fields = []
        @hidden_fields = []
      end

      def tag_filter
        create_filter_builder(TagFilterBuilder)
      end

      def teachable_filter
        create_filter_builder(TeachableFilterBuilder)
      end

      def medium_type_filter(purpose: "media")
        create_filter_builder(MediumTypeFilterBuilder, purpose: purpose)
      end

      def fulltext_filter
        create_filter_builder(FulltextFilterBuilder)
      end

      def editor_filter
        create_filter_builder(EditorFilterBuilder)
      end

      def medium_access_filter
        create_filter_builder(MediumAccessFilterBuilder)
      end

      def answer_count_filter(purpose: "media")
        create_filter_builder(AnswerCountFilterBuilder, purpose: purpose)
      end

      def hidden_field(**fields)
        fields.each do |name, value|
          @hidden_fields << { name: name, value: value }
        end
        self
      end

      def build_form(url:, **form_options)
        SearchForm.new(url: url, **form_options).tap do |form|
          @fields.each { |field| form.with_field(field) }
          @hidden_fields.each { |hf| form.with_hidden_field(name: hf[:name], value: hf[:value]) }
        end
      end

      private

        def create_filter_builder(builder_class, **options)
          # Create builder with form_state and any additional options
          builder = if options.any?
            builder_class.new(@form_state, **options)
          else
            builder_class.new(@form_state)
          end

          # Build the filter and add to @fields
          filter = builder.build
          @fields << filter

          # Return the builder for chaining
          builder
        end
    end
  end
end
