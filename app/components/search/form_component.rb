module Search
  class FormComponent < ViewComponent::Base
    renders_many :fields, lambda { |component, &block|
      if block && component.respond_to?(:with_content)
        # Pass the component into the block just like your view expects (|field|)
        component.with_content { block.call(component) }
      end
      component
    }
    renders_one :header, Search::HeaderComponent
    renders_one :footer, Search::FooterComponent
    renders_many :hidden_fields, Search::HiddenFieldComponent

    attr_reader :url, :scope, :method, :remote, :submit_label

    def initialize(url:, scope: :search, method: :get, remote: true, submit_label: nil)
      super()
      @url = url
      @scope = scope
      @method = method
      @remote = remote
      @submit_label = submit_label || I18n.t("basics.search")
    end
  end
end
