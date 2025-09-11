# SearchForm is a flexible ViewComponent for building search interfaces.
#
# This component provides a declarative API for creating search forms with various
# field types (text, select, multi-select, etc.) and handles form state management,
# accessibility, and styling automatically.
#
# @example Basic usage
#   <%= render(SearchForm::SearchForm.new(url: search_path)) do |c| %>
#     <% c.add_fulltext_field %>
#     <% c.add_medium_type_field %>
#     <% c.add_submit_field %>
#   <% end %>
#
# @example With context and options
#   <%= render(SearchForm::SearchForm.new(
#         url: media_search_path,
#         context: "media",
#         scope: :media_search,
#         method: :post
#       )) do |c| %>
#     <% c.add_teacher_field(prompt: "Choose instructor") %>
#     <% c.add_tag_field_with_operators %>
#   <% end %>
#
# The component automatically generates field methods based on the FieldRegistry
# configuration, providing a consistent API for all field types.
module SearchForm
  class SearchForm < ViewComponent::Base
    # ViewComponent's `renders_many` allows passing a `lambda`, which we use here
    # as a hook to intercept every field component before it's rendered. This
    # lambda's primary purpose is to automatically inject the shared @form_state
    # instance into each field.
    #
    # This dependency injection is crucial because it provides every field with:
    # - Access to the form builder (`form_with` instance).
    # - The shared context for generating unique and accessible HTML IDs.
    #
    # By handling this automatically, we avoid having to manually pass the
    # form_state to every `add_*_field` or `with_field` call, simplifying the
    # public API of the component.
    renders_many :fields, lambda { |component, &block|
      # Auto-inject form_state if needed
      if component.respond_to?(:form_state=) && component.form_state.nil?
        component.form_state = @form_state
      end

      # Pass along any content block to the field component.
      component.with_content(&block) if block
      component
    }

    attr_reader :url, :scope, :method, :remote, :context, :hidden_fields, :container_class

    # Initializes a new SearchForm component.
    #
    # @param url [String] The form submission URL
    # @param scope [Symbol] The form scope for parameter namespacing (default: :search)
    # @param method [Symbol] HTTP method for form submission (default: :get)
    # @param remote [Boolean] Whether to submit via AJAX (default: true)
    # @param context [String, nil] Context identifier for styling and behavior
    # @param container_class [String] CSS classes for the main container div
    # rubocop:disable Metrics/ParameterLists
    def initialize(url:, scope: :search, method: :get, remote: true, context: nil,
                   container_class: "row mb-3 p-2")
      super()
      @url = url
      @scope = scope
      @method = method
      @remote = remote
      @context = context || SecureRandom.hex(4)
      @form_state = Services::FormState.new(context: @context)
      @hidden_fields = {}
      @container_class = container_class
    end
    # rubocop:enable Metrics/ParameterLists

    # Adds a hidden field to the form.
    #
    # @param name [Symbol, String] The field name
    # @param value [String] The field value
    def add_hidden_field(name:, value:)
      @hidden_fields[name] = value
    end

    # Adds a submit button to the form.
    #
    # @param label [String, nil] Button text (defaults to I18n lookup)
    # @param css_classes [String] CSS classes for the button
    # @param options [Hash] Additional options passed to the submit field
    def add_submit_field(label: nil, css_classes: "btn btn-primary", **)
      with_field(Fields::Primitives::SubmitField.new(
                   label: label,
                   css_classes: css_classes,
                   **
                 ))
    end

    # Returns the field registry instance for this form.
    #
    # The registry handles dynamic field method generation and field creation.
    # @return [FieldRegistry] The registry instance
    def field_registry
      @field_registry ||= Services::FieldRegistry.new(self)
    end

    # Generate field methods at class level
    Services::FieldRegistry.generate_methods_for(self)
  end
end
