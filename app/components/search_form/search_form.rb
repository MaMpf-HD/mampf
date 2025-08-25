# app/components/search_form/search_form.rb
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

    # Access to the filter registry
    def filter_registry
      @filter_registry ||= FilterRegistry.new(self)
    end

    # Generate filter methods at class level
    FilterRegistry.generate_methods_for(self)
  end
end
