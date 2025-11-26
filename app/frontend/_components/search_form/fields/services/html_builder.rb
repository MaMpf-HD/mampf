module SearchForm
  module Fields
    module Services
      # A service class that centralizes the logic for building HTML attribute hashes
      # for form field elements. It is responsible for generating unique IDs,
      # consolidating CSS classes, adding accessibility (ARIA) attributes, and
      # preparing options for select tags.
      class HtmlBuilder
        # Initializes a new HtmlBuilder.
        #
        # @param field_data [SearchForm::Fields::Services::FieldData] The field data object
        # that this builder serves.
        def initialize(field_data)
          @field_data = field_data
        end

        # A base method for creating an options hash that always includes a unique ID.
        #
        # @param additional_options [Hash] Extra options to merge.
        # @return [Hash] An options hash guaranteed to contain a unique `id` attribute.
        def html_options_with_id(additional_options = {})
          @field_data.options.merge(id: element_id).merge(additional_options)
        end

        # Builds the main HTML options hash for a field element (e.g., `<input>`, `<select>`).
        # It combines CSS classes from the `CssManager`, accessibility attributes,
        # a unique ID, and any additional options passed in.
        #
        # @param additional_options [Hash] Extra options to merge into the final hash.
        # @return [Hash] The final HTML options hash for the field element.
        def field_html_options(additional_options = {})
          default_options = { class: css_manager.field_css_classes }
          accessibility_options = build_accessibility_attributes

          html_options_with_id(default_options.merge(accessibility_options)
                                              .merge(additional_options))
        end

        # Builds the options hash for the Rails `form.select` helper (its 3rd argument),
        # specifically handling the `:prompt` and `:selected` keys.
        #
        # @return [Hash] An options hash containing `:prompt` and/or `:selected` if applicable.
        def select_tag_options
          options = {}
          options[:prompt] = resolve_prompt_text if should_add_prompt?
          options[:selected] = @field_data.selected if @field_data.selected.present?
          options
        end

        # Generates a unique ID for the field element by delegating to the `form_state`.
        # If `use_value_in_id` is true, it appends the field's value.
        #
        # @return [String] A unique HTML ID for the field element.
        def element_id
          parts = [@field_data.name]
          parts << @field_data.value if @field_data.use_value_in_id && @field_data.value.present?
          @field_data.form_state.element_id_for(*parts)
        end

        # Generates the value for the `<label>` tag's `for` attribute.
        # If `use_value_in_id` is true, it appends the field's value.
        #
        # @return [String] The ID to be used in the `for` attribute.
        def label_for
          parts = [@field_data.name]
          parts << @field_data.value if @field_data.use_value_in_id && @field_data.value.present?
          @field_data.form_state.label_for(*parts)
        end

        # Generates the ID for the help text element, used for `aria-describedby`.
        #
        # @return [String] The unique ID for the help text `<span>`.
        def help_text_id
          "#{element_id}_help"
        end

        private

          attr_reader :field_data

          def css_manager
            @css_manager ||= CssManager.new(@field_data)
          end

          def should_add_prompt?
            @field_data.prompt.present?
          end

          def resolve_prompt_text
            @field_data.prompt.is_a?(String) ? @field_data.prompt : I18n.t("basics.select")
          end

          def build_accessibility_attributes
            attributes = {}

            attributes[:"aria-describedby"] = help_text_id if @field_data.show_help_text?
            attributes[:"aria-required"] = "true" if field_required?

            attributes
          end

          def field_required?
            [true, "required"].include?(@field_data.options[:required])
          end
      end
    end
  end
end
