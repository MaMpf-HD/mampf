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
    end
  end
end
