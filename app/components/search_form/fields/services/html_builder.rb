module SearchForm
  module Fields
    module Services
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
          accessibility_options = build_accessibility_attributes

          html_options_with_id(default_options.merge(accessibility_options)
                                              .merge(additional_options))
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

        # Generate aria-describedby ID for help text
        def help_text_id
          "#{element_id}_help"
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

          def build_accessibility_attributes
            attributes = {}

            # Add aria-describedby for help text
            attributes[:"aria-describedby"] = help_text_id if @field.show_help_text?

            # Add aria-required for required fields
            attributes[:"aria-required"] = "true" if field_required?

            # Add aria-label for submit buttons
            attributes[:"aria-label"] = @field.label if @field.is_a?(Fields::SubmitField)

            attributes
          end

          def field_required?
            [true, "required"].include?(@field.options[:required])
          end
      end
    end
  end
end
