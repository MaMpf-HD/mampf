module SearchForm
  module Controls
    class RadioGroup < ViewComponent::Base
      attr_reader :form, :name, :options

      renders_many :radio_buttons, RadioButton

      def initialize(form:, name:, **options)
        super()
        @form = form
        @name = name
        @options = options
      end

      # Determines the CSS class for the component's container element.
      # Can be customized by passing container_class: "your-class" to
      # the component.
      def container_class
        options[:container_class] || "mt-2"
      end
    end
  end
end
