class PlaceholderTabComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(message:)
    super()
    @message = message
  end

  attr_reader :message
end
