class PartialTabComponent < ViewComponent::Base
  # Missing top-level docstring, please formulate one yourself 😁

  def initialize(partial:, locals: {})
    super()
    @partial = partial
    @locals = locals
  end

  def call
    render(partial: @partial, locals: @locals)
  end
end
