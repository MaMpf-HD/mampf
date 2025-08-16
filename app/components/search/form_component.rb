module Search
  class FormComponent < ViewComponent::Base
    renders_many :fields, ->(component) { component }
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

    # Add this class for hidden fields
    class HiddenFieldComponent < ViewComponent::Base
      attr_reader :name, :value

      def initialize(name:, value:)
        super()
        @name = name
        @value = value
      end

      def call
        # Empty - we'll render this manually
      end
    end

    # Use the component class for rendering many
    renders_many :hidden_fields, HiddenFieldComponent
  end
end
