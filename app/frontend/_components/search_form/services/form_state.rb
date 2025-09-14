# FormState is a service object that manages state related to HTML form rendering.
# It has two primary, highly-cohesive responsibilities:
#
# - **Form Builder Carrier:** It acts as a central container for the
#   `ActionView::Helpers::FormBuilder` instance. This is necessary because the
#   FormState is created before the form builder, but the fields need access
#   to the builder during rendering. The `with_form` method is used to inject
#   the builder at render time.
#
# - **ID Generation:** It generates unique and consistent HTML `id` and `for`
#   attributes for form fields and their labels. This ensures accessibility
#   and prevents ID collisions.
#
# @example Lifecycle
#   # In SearchForm#initialize
#   @form_state = FormState.new(context: "media")
#
#   # In SearchForm's template, the form builder `f` is created
#   <%= form_with ... do |f| %>
#     # The builder is passed to the field, which passes it to FormState
#     <%= render field.with_form(f) %>
#   <% end %>
#
#   # The field can now access the form builder via the form_state
#   # e.g., form_state.form.text_field(...)
#
module SearchForm
  module Services
    class FormState
      attr_reader :form, :context, :scope_prefix

      # Initializes a new FormState instance.
      #
      # @param form [ActionView::Helpers::FormBuilder, nil]
      # The form builder, optional at initialization.
      # @param context [String, nil] A unique context string for the form (e.g., "media_search").
      def initialize(form: nil, context: nil)
        @form = form
        @context = context
        @scope_prefix = form&.object_name || "search"
      end

      # Associates the state with a Rails form builder instance after initialization.
      # This is the crucial step that makes the form builder available to all fields.
      #
      # @param form [ActionView::Helpers::FormBuilder] The form builder instance from `form_with`.
      # @return [self] Returns itself to allow for method chaining.
      def with_form(form)
        @form = form
        @scope_prefix = form&.object_name || "search"
        self
      end

      # Generates the base ID string, which includes the context but not the form scope.
      # This is the core identifier for a field and its related elements.
      #
      # @param parts [Array<String, Symbol>] One or more parts to build the ID from.
      # @return [String] The context-aware base ID string.
      # @return [String] The context-aware base ID string.
      def base_id_for(*parts)
        (Array(context).compact_blank + parts.map(&:to_s).reject(&:empty?)).join("_")
      end

      # Generates the full, globally unique element ID, including the form scope.
      # This is suitable for use in an HTML `id` attribute.
      #
      # @param parts [Array<String, Symbol>] One or more parts to build the ID from.
      # @return [String] The full, scoped element ID.
      def element_id_for(*parts)
        [scope_prefix, base_id_for(*parts)].compact.join("_")
      end

      # Generates the identifier for a label's `for` attribute.
      # This returns the base ID without the form scope, as the Rails `form.label`
      # helper automatically adds the scope.
      #
      # @param parts [Array<String, Symbol>] One or more parts to build the ID from.
      # @return [String] The unscoped ID for a label's `for` attribute.
      def label_for(*parts)
        base_id_for(*parts)
      end
    end
  end
end
