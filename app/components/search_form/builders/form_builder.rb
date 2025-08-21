module SearchForm
  module Builders
    class FormBuilder
      def initialize(form_state)
        @form_state = form_state
        @fields = []
        @hidden_fields = []
      end

      # Simple filters (no special configuration needed)
      ["editor", "medium_access", "fulltext"].each do |filter_name|
        define_method "#{filter_name}_filter" do
          create_simple_filter("SearchForm::Filters::#{filter_name.camelize}Filter".constantize)
        end
      end

      # Parameterized filters
      def medium_type_filter(purpose: "media")
        create_simple_filter(Filters::MediumTypeFilter, purpose: purpose)
      end

      def answer_count_filter(purpose: "media")
        create_simple_filter(Filters::AnswerCountFilter, purpose: purpose)
      end

      def per_page_filter(per_options: [[10, 10], [20, 20], [50, 50]], default: 10, id: nil)
        create_simple_filter(Filters::PerPageFilter, per_options: per_options, default: default,
                                                     id: id)
      end

      # Complex filters with custom builders (that have special methods)
      def tag_filter
        create_filter_builder(TagFilterBuilder)
      end

      def teachable_filter
        create_filter_builder(TeachableFilterBuilder)
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

        def create_simple_filter(filter_class, **)
          builder = SimpleFilterBuilder.new(@form_state, filter_class, **)
          filter = builder.build
          @fields << filter
          builder
        end

        def create_filter_builder(builder_class, **options)
          builder = if options.any?
            builder_class.new(@form_state, **options)
          else
            builder_class.new(@form_state)
          end

          filter = builder.build
          @fields << filter
          builder
        end
    end
  end
end
