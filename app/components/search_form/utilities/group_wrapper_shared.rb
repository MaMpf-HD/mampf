module SearchForm
  module Utilities
    # Shared functionality for group wrapper classes
    module GroupWrapperShared
      attr_reader :parent_field, :options

      # Allow the wrapper to be used with <%= %> in templates
      def wrap(view_context, &)
        render(view_context, &)
      end

      private

        # Resolve aria-labelledby from explicit value or parent field
        def resolved_aria_labelledby
          return @options[:aria_labelledby] if @options[:aria_labelledby]
          return @parent_field.form_state.element_id_for(@parent_field.name) if @parent_field

          nil
        end

        # Auto-render a collection of components if no block is provided
        def auto_render_collection(view_context, collection, wrapper_class: nil, &block)
          content = []

          if block
            content << view_context.capture(&block)
          elsif collection.any?
            rendered_items = collection.map { |item| view_context.render(item) }

            content << if wrapper_class
              view_context.content_tag(:div, class: wrapper_class) do
                view_context.safe_join(rendered_items)
              end
            else
              view_context.safe_join(rendered_items)
            end
          end

          view_context.safe_join(content)
        end
    end
  end
end
