module SearchForm
  class SearchForm < ViewComponent::Base
    renders_many :fields, lambda { |component, &block|
      # Inject the form_state into each field component
      if component.respond_to?(:form_state=) && component.form_state.nil?
        component.form_state = @form_state
      end

      component.with_content(&block) if block
      component
    }
    renders_one :header, Layout::Header
    renders_one :footer, Layout::Footer
    renders_many :hidden_fields, Fields::HiddenField

    attr_reader :url, :scope, :method, :remote, :submit_label, :context

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
    end
  end
end
