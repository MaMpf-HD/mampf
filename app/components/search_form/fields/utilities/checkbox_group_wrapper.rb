module SearchForm
  module Fields
    module Utilities
      # A lightweight utility class that provides accessibility markup for checkbox groups.
      # Can automatically extract attributes from a parent field and handle multiple checkboxes.
      class CheckboxGroupWrapper
        include GroupWrapperShared

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
        def render(view_context, &)
          content = auto_render_collection(view_context, @checkboxes, &)

          if @wrap_in_group
            view_context.content_tag(:div, group_options) { content }
          else
            content
          end
        end

        private

          def group_options
            base_options = {
              role: "group"
            }

            # Use resolved aria-labelledby from GroupWrapperShared
            if resolved_aria_labelledby.present?
              base_options[:"aria-labelledby"] = resolved_aria_labelledby
            end

            base_options.merge(@options.except(:aria_labelledby))
          end
      end
    end
  end
end
