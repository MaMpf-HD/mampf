module SearchForm
  module Fields
    class HiddenField < ViewComponent::Base
      attr_reader :name, :value

      def initialize(name:, value:)
        super()
        @name = name
        @value = value
      end
    end
  end
end
