module SearchForm
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

    attr_reader :url, :scope, :method, :remote, :submit_label, :context, :hidden_fields

    def initialize(url:, scope: :search, method: :get, remote: true, submit_label: nil,
                   context: nil)
      super()
      @url = url
      @scope = scope
      @method = method
      @remote = remote
      @submit_label = submit_label || I18n.t("basics.search")
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
  end
end
