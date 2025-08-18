module Search
  module Controls
    class RadioGroupComponent < ViewComponent::Base
      attr_reader :form, :name, :options

      renders_many :radio_buttons, RadioButtonComponent

      def initialize(form:, name:, **options)
        super()
        @form = form
        @name = name
        @options = options
      end
    end
  end
end
