module SearchForm
  module Builders
    class FilterRegistry
      # All filters with their configurations in one place
      FILTERS = {
        # Simple filters
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

        # Complex filters
        "tag" => {
          methods: [:with_operator_radios]
        },
        "teachable" => {
          methods: [:with_inheritance_radios]
        },
        "course" => {
          methods: [:with_edited_courses_button],
          method_configs: {
            with_edited_courses_button: {
              wrapper: :with_content
            }
          }
        },
        "lecture_scope" => {
          methods: [:with_lecture_options]
        }
      }.freeze

      class << self
        def all_filters
          FILTERS
        end

        def filter_config(filter_name)
          FILTERS[filter_name] || {}
        end

        def simple_filter?(filter_name)
          !complex_filter?(filter_name)
        end

        def complex_filter?(filter_name)
          filter_config(filter_name).key?(:methods)
        end

        def filter_names
          FILTERS.keys
        end

        def simple_filter_names
          FILTERS.reject { |_, config| config.key?(:methods) }.keys
        end

        def complex_filter_names
          FILTERS.select { |_, config| config.key?(:methods) }.keys
        end
      end
    end
  end
end
