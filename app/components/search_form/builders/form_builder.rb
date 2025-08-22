module SearchForm
  module Builders
    class FormBuilder
      # All simple filters with their default configurations
      SIMPLE_FILTERS = {
        "editor" => {},
        "medium_access" => {},
        "fulltext" => {},
        "teacher" => {},
        "lecture_type" => {},
        "term" => {},
        "program" => {},
        "term_independence" => {},
        "tag_title" => {},
        "medium_type" => { purpose: "media" },
        "answer_count" => { purpose: "media" },
        "per_page" => {
          per_options: [[10, 10], [20, 20], [50, 50]],
          default: 10,
          id: nil
        }
      }.freeze

      # Complex filters have dedicated builders with special configuration methods
      COMPLEX_FILTERS = ["tag", "teachable", "course", "lecture_scope"].freeze

      def initialize(form_state)
        @form_state = form_state
        @filter_manager = FilterManager.new(form_state) # or FilterBuilderFactory
        @fields = []
        @hidden_fields = []
      end

      # Dynamically define simple filter methods
      SIMPLE_FILTERS.each do |filter_name, default_options|
        define_method "#{filter_name}_filter" do |**options|
          merged_options = default_options.merge(options)
          filter = @filter_manager.build_simple_filter(filter_name, **merged_options)
          @fields << filter
          filter
        end
      end

      # Dynamically define complex filter methods
      COMPLEX_FILTERS.each do |filter_name|
        define_method "#{filter_name}_filter" do |**options|
          builder = @filter_manager.create_complex_filter_builder(filter_name, **options)
          @fields << builder.build
          builder
        end
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

        attr_reader :filter_factory
    end
  end
end
