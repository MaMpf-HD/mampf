module SearchForm
  module Fields
    module Services
      # HTML attribute building service for form fields
      #
      # This service object handles the construction of HTML attributes
      # for form fields, including IDs, CSS classes, data attributes,
      # and options for select fields. It provides consistent HTML
      # generation across different field types.
      #
      # Features:
      # - Consistent ID generation using form state
      # - CSS class management integration
      # - Select field options handling (prompts, selected values)
      # - HTML attribute merging and validation
      # - Accessibility attribute support
      #
      # @example Basic usage
      #   html_builder = HtmlBuilder.new(field)
      #   html_builder.field_html_options(data: { controller: "select2" })
      #   # => { id: "search_term", class: "form-control", data: { controller: "select2" } }
      #
      # The service works closely with CssManager and form_state to
      # provide complete HTML attribute management.
      class HtmlBuilder
        def initialize(field)
          @field = field
        end

        # Common method for building HTML options with ID
        def html_options_with_id(additional_options = {})
          @field.options.merge(id: element_id).merge(additional_options)
        end

        # Common method for building HTML options with field CSS classes
        def field_html_options(additional_options = {})
          default_options = { class: css_manager.field_css_classes }
          html_options_with_id(default_options.merge(additional_options))
        end

        # Standardized select tag options that handle prompts
        def select_tag_options
          options = {}
          options[:prompt] = resolve_prompt_text if should_add_prompt?
          options[:selected] = @field.selected if @field.selected.present?
          options
        end

        # Generate a unique ID using form_state
        def element_id
          @field.form_state.element_id_for(@field.name)
        end

        # Public ID for the <label for="..."> attribute
        def label_for
          @field.form_state.label_for(@field.name)
        end

        private

          attr_reader :field

          def css_manager
            @css_manager ||= CssManager.new(@field)
          end

          def should_add_prompt?
            @field.prompt.present?
          end

          def resolve_prompt_text
            @field.prompt.is_a?(String) ? @field.prompt : I18n.t("basics.select")
          end
      end
    end
  end
end
