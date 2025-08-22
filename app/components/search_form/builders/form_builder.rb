module SearchForm
  module Builders
    class FormBuilder
      # All filters with their configurations in one place
      FILTERS = {
        # Simple filters (no methods = simple)
        "editor" => {},
        "medium_access" => {},
        "fulltext" => {},
        "teacher" => {},
        "lecture_type" => {},
        "term" => {},
        "program" => {},
        "term_independence" => {},
        "tag_title" => {},

        # Simple filters with default options
        "medium_type" => {
          defaults: { purpose: "media" }
        },
        "answer_count" => {
          defaults: { purpose: "media" }
        },
        "per_page" => {
          defaults: {
            per_options: [[10, 10], [20, 20], [50, 50]],
            default: 10,
            id: nil
          }
        },

        # Complex filters (has :methods = complex)
        "tag" => {
          methods: [:with_ajax, :with_operator_radios],
          method_configs: {
            with_ajax: {
              target_method: :configure_ajax,
              default_args: { model: "tag", locale: nil, no_results: nil }
            },
            with_operator_radios: {
              target_method: :with_operator_radios
            }
          }
        },
        "teachable" => {
          methods: [:with_inheritance_radios],
          method_configs: {
            with_inheritance_radios: {
              target_method: :with_inheritance_radios
            }
          }
        },
        "course" => {
          methods: [:with_edited_courses_button],
          method_configs: {
            with_edited_courses_button: {
              target_method: :render_edited_courses_button,
              wrapper: :with_content
            }
          }
        },
        "lecture_scope" => {
          methods: [:with_lecture_options],
          method_configs: {
            with_lecture_options: {
              target_method: :with_lecture_options
            }
          }
        }
      }.freeze

      def initialize(form_state)
        @form_state = form_state
        @filter_manager = FilterManager.new(form_state)
        @fields = []
        @hidden_fields = []
      end

      # Dynamically define ALL filter methods
      FILTERS.each do |filter_name, config|
        define_method "#{filter_name}_filter" do |**options|
          if config.key?(:methods) # Complex filter
            builder = @filter_manager.create_dynamic_filter_builder(filter_name, config, **options)
            @fields << builder.build
            builder
          else # Simple filter
            merged_options = (config[:defaults] || {}).merge(options)
            filter = @filter_manager.build_simple_filter(filter_name, **merged_options)
            @fields << filter
            filter
          end
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

        attr_reader :filter_manager
    end
  end
end
