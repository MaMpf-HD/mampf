module SearchForm
  module Fields
    module Utilities
      # Provides shared functionality for wrapper components that group other form
      # fields, such as `CheckboxGroupWrapper` and `RadioGroupWrapper`. It handles
      # rendering collections of child components and resolving ARIA attributes.
      module GroupWrapperShared
        attr_reader :parent_field, :options

        # Provides an alias for #render, allowing the wrapper to be used directly
        # with `<%= %>` syntax in ERB templates.
        def wrap(view_context, &)
          render(view_context, &)
        end

        private

          # Resolves the ID to be used for `aria-labelledby`.
          # It prioritizes an explicitly passed `:aria_labelledby` option. If not
          # present, it falls back to generating an ID based on the parent field's name.
          def resolved_aria_labelledby
            return @options[:aria_labelledby] if @options[:aria_labelledby]
            return @parent_field.form_state.element_id_for(@parent_field.name) if @parent_field

            nil
          end

          # Renders a collection of components, either from a passed block or from
          # a collection of component instances.
          #
          # SECURITY: This method uses `safe_join` to concatenate rendered components.
          # The output of `view_context.render(item)` is already an HTML-safe string
          # (`ActiveSupport::SafeBuffer`). `safe_join` trusts these pre-marked strings.
          # Therefore, the security of this method relies on the individual components
          # (`item` in the collection) being secure and not misusing `raw()` or
          # `.html_safe` on untrusted user input.
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
end
