# Search Form Component System
#
# This is the main search form component that provides a flexible,
# ViewComponent-based system for building search interfaces with filters.
# It supports dynamic filter registration, auto-generated convenience methods,
# and proper form state management.
#
# Key features:
# - Dynamic filter method generation via FilterRegistry
# - Auto-injection of form_state into filter components
# - Support for both regular fields and hidden fields
# - AJAX-enabled forms with Stimulus integration
#
# Usage:
#   <%= render(SearchForm::SearchForm.new(url: search_path, context: "media")) do |c| %>
#     <% c.add_medium_type_filter(current_user: current_user) %>
#     <% c.add_tag_filter_with_operators %>
#     <% c.add_submit_field %>
#   <% end %>

module SearchForm
  # Main search form component that orchestrates filters and form rendering
  #
  # This component manages the overall form structure, handles form state injection
  # into child components, and provides convenience methods for adding filters
  # and form fields.
  #
  # @example Basic usage
  #   SearchForm::SearchForm.new(url: "/search", context: "media")
  #
  # @example With custom form options
  #   SearchForm::SearchForm.new(
  #     url: "/advanced_search",
  #     method: :post,
  #     remote: false,
  #     context: "admin"
  #   )
  class SearchForm < ViewComponent::Base
    include FilterRegistry

    renders_many :fields, lambda { |component, &block|
      # Auto-inject form_state if needed
      if component.respond_to?(:form_state=) && component.form_state.nil?
        component.form_state = @form_state
      end

      component.with_content(&block) if block
      component
    }

    attr_reader :url, :scope, :method, :remote, :context, :hidden_fields

    def initialize(url:, scope: :search, method: :get, remote: true, context: nil)
      super()
      @url = url
      @scope = scope
      @method = method
      @remote = remote
      @context = context
      @form_state = FormState.new(context: context)
      @hidden_fields = {}
    end

    def add_field(component, &)
      with_field(component, &)
    end

    def add_hidden_field(name:, value:)
      @hidden_fields[name] = value
    end

    # Manual method for submit field (not a filter)
    def add_submit_field(label: nil, css_classes: "btn btn-primary", **)
      with_field(Fields::SubmitField.new(
                   label: label,
                   css_classes: css_classes,
                   **
                 ))
    end
  end
end
