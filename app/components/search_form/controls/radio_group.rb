module SearchForm
  module Controls
    class RadioGroup < BaseControl
      attr_reader :name

      renders_many :radio_buttons, RadioButton

      def initialize(form:, name:, **)
        super(form: form, **)
        @name = name
      end

      # Override the default container class
      def default_container_class
        "mt-2"
      end
    end
  end
end
