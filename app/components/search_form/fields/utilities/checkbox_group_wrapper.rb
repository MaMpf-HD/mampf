module SearchForm
  module Fields
    module Utilities
      # Wraps a collection of checkbox components within a `div` element that has
      # `role="group"`. This is essential for accessibility, as it semantically
      # groups related checkboxes under a common label (e.g., a multi-select's label).
      # It can also render the checkboxes without the wrapper if needed.
      class CheckboxGroupWrapper
        include GroupWrapperShared
        attr_reader :checkboxes

        # Initializes the wrapper.
        #
        # @param checkboxes [Array<CheckboxField>] A list of checkbox component instances
        # to be wrapped.
        # @param parent_field [Field] The parent field component that this group is associated with.
        #   Used to automatically resolve the `aria-labelledby` attribute.
        # @param wrap_in_group [Boolean] If false, the wrapper div will be omitted, and the
        #   checkboxes will be rendered directly. Defaults to true.
        # @param options [Hash] A hash of additional HTML attributes to be applied to the
        # wrapper div.
        def initialize(checkboxes: [], parent_field: nil, wrap_in_group: true, **options)
          @checkboxes = checkboxes.flatten
          @parent_field = parent_field
          @wrap_in_group = wrap_in_group
          @options = options
        end

        # Sets the checkboxes to be rendered by the wrapper.
        #
        # @param buttons [Array<CheckboxField>] A list of checkbox component instances.
        # @return [self] Returns the instance for method chaining.
        def with_checkboxes(*buttons)
          @checkboxes = buttons.flatten
          self
        end

        # Renders the checkbox group.
        # If `@wrap_in_group` is true, it renders a `div` with `role="group"` and
        # `aria-labelledby` pointing to the parent field's label. Inside this div,
        # it renders the collection of checkboxes. If false, it renders only the
        # checkboxes.
        #
        # @param view_context [ActionView::Base] The view context for rendering.
        # @param &block A block that can be used to render custom content inside the group.
        # @return [ActiveSupport::SafeBuffer] The HTML-safe string representing the rendered group.
        def render(view_context = nil, &)
          context = view_context || self
          content = auto_render_collection(context, @checkboxes, &)

          return content unless @wrap_in_group

          group_options = @options.merge(
            role: "group",
            "aria-labelledby": resolved_aria_labelledby
          )

          context.content_tag(:div, group_options) { content }
        end
      end
    end
  end
end
