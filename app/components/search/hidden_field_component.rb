module Search
  class HiddenFieldComponent < ViewComponent::Base
    attr_reader :name, :value

    def initialize(name:, value:)
      super()
      @name = name
      @value = value
    end
  end
end
