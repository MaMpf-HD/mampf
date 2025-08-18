module SearchForm
  class FormComponent < ViewComponent::Base
    renders_many :fields, lambda { |component, &block|
      if @context.present? && component.respond_to?(:context=) && component.context.nil?
        component.context = @context
      end

      component.with_content(&block) if block
      component
    }
    renders_one :header, SearchForm::HeaderComponent
    renders_one :footer, SearchForm::FooterComponent
    renders_many :hidden_fields, SearchForm::HiddenFieldComponent

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
    end
  end
end
