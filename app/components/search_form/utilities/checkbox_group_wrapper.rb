module SearchForm
  module Utilities
    # A lightweight utility class that provides accessibility markup for checkbox groups.
    # Can automatically extract attributes from a parent field and handle multiple checkboxes.
    class CheckboxGroupWrapper
      attr_reader :parent_field, :checkboxes, :options

      def initialize(parent_field: nil, checkboxes: [], wrap_in_group: true, **options)
        @parent_field = parent_field
        @checkboxes = checkboxes.flatten
        @wrap_in_group = wrap_in_group
        @options = options
      end

      # Add checkboxes to the wrapper
      def with_checkboxes(*checkboxes)
        @checkboxes = checkboxes.flatten
        self
      end

      # Renders the checkboxes with proper accessibility markup
      def render(view_context, &block)
        if @wrap_in_group
          view_context.content_tag(:div, group_options) do
            render_content(view_context, &block)
          end
        else
          render_content(view_context, &block)
        end
      end

      # Allow the wrapper to be used with <%= %> in templates
      def wrap(view_context, &)
        render(view_context, &)
      end

      private

        def render_content(view_context, &block)
          content = []

          if block
            content << view_context.capture(&block)
          elsif @checkboxes.any?
            # Auto-render the checkboxes if no block is provided
            content << view_context.safe_join(@checkboxes.map { |checkbox|
              view_context.render(checkbox)
            })
          end

          view_context.safe_join(content)
        end

        def group_options
          base_options = {
            role: "group"
          }

          # Use resolved aria-labelledby
          if resolved_aria_labelledby.present?
            base_options[:"aria-labelledby"] = resolved_aria_labelledby
          end

          base_options.merge(@options.except(:aria_labelledby))
        end

        # Resolve aria-labelledby from explicit value or parent field
        def resolved_aria_labelledby
          return @options[:aria_labelledby] if @options[:aria_labelledby]
          return @parent_field.form_state.element_id_for(@parent_field.name) if @parent_field

          nil
        end
    end
  end
end
