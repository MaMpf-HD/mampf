# app/components/search_form/search_form.rb

# SearchForm is a flexible ViewComponent for building search interfaces.
#
# This component provides a declarative API for creating search forms with various
# filter types (text, select, multi-select, etc.) and handles form state management,
# accessibility, and styling automatically.
#
# @example Basic usage
#   <%= render(SearchForm::SearchForm.new(url: search_path)) do |c| %>
#     <% c.add_fulltext_filter %>
#     <% c.add_medium_type_filter %>
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
#     <% c.add_teacher_filter(prompt: "Choose instructor") %>
#     <% c.add_tag_filter_with_operators %>
#   <% end %>
#
# The component automatically generates filter methods based on the FilterRegistry
# configuration, providing a consistent API for all filter types.
module SearchForm
  class SearchForm < ViewComponent::Base
    renders_many :fields, lambda { |component, &block|
      # Auto-inject form_state if needed
      if component.respond_to?(:form_state=) && component.form_state.nil?
        component.form_state = @form_state
      end

      component.with_content(&block) if block
      component
    }

    attr_reader :url, :scope, :method, :remote, :context, :hidden_fields

    # Initializes a new SearchForm component.
    #
    # @param url [String] The form submission URL
    # @param scope [Symbol] The form scope for parameter namespacing (default: :search)
    # @param method [Symbol] HTTP method for form submission (default: :get)
    # @param remote [Boolean] Whether to submit via AJAX (default: true)
    # @param context [String, nil] Context identifier for styling and behavior
    def initialize(url:, scope: :search, method: :get, remote: true, context: nil)
      super()
      @url = url
      @scope = scope
      @method = method
      @remote = remote
      @context = context
      @form_state = Services::FormState.new(context: context)
      @hidden_fields = {}
    end

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
      with_field(Fields::SubmitField.new(
                   label: label,
                   css_classes: css_classes,
                   **
                 ))
    end

    # Returns the filter registry instance for this form.
    #
    # The registry handles dynamic filter method generation and filter creation.
    # @return [FilterRegistry] The registry instance
    def filter_registry
      @filter_registry ||= Services::FilterRegistry.new(self)
    end

    # Generate filter methods at class level
    Services::FilterRegistry.generate_methods_for(self)
  end
end
