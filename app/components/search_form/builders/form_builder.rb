module SearchForm
  module Builders
    class FormBuilder
      # Simple filters use SimpleFilterBuilder and work directly with filter classes
      SIMPLE_FILTERS = [
        "editor", "medium_access", "fulltext", "teacher", "lecture_type",
        "term", "program", "term_independence", "tag_title"
      ].freeze

      # Complex filters have dedicated builders with special configuration methods
      # (like .with_ajax, .with_operator_radios, .with_inheritance_radios, etc.)
      COMPLEX_FILTERS = ["tag", "teachable", "course", "lecture_scope"].freeze

      def initialize(form_state)
        @form_state = form_state
        @fields = []
        @hidden_fields = []
      end

      # Dynamically define simple filter methods
      SIMPLE_FILTERS.each do |filter_name|
        define_method "#{filter_name}_filter" do |**options|
          filter_class = "SearchForm::Filters::#{filter_name.camelize}Filter".constantize
          create_simple_filter(filter_class, **options)
        end
      end

      # Dynamically define complex filter methods
      COMPLEX_FILTERS.each do |filter_name|
        define_method "#{filter_name}_filter" do |**options|
          builder_class = "SearchForm::Builders::#{filter_name.camelize}FilterBuilder".constantize
          create_filter_builder(builder_class, **options)
        end
      end

      # Parameterized filters that need special default handling
      def medium_type_filter(purpose: "media", **)
        create_simple_filter(Filters::MediumTypeFilter, purpose: purpose, **)
      end

      def answer_count_filter(purpose: "media", **)
        create_simple_filter(Filters::AnswerCountFilter, purpose: purpose, **)
      end

      def per_page_filter(per_options: [[10, 10], [20, 20], [50, 50]], default: 10, id: nil,
                          **)
        create_simple_filter(Filters::PerPageFilter, per_options: per_options, default: default,
                                                     id: id, **)
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
