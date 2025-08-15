module Search
  class FormComponent < ViewComponent::Base
    renders_many :fields, ->(component) { component }
    renders_many :hidden_fields, ->(name, value) { { name: name, value: value } if name.present? }
    renders_one :header, lambda { |options = {}|
      Search::HeaderComponent.new(**options)
    }

    renders_one :footer, lambda { |options = {}|
      Search::FooterComponent.new(**options)
    }

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
