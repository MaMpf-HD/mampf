module SearchForm
  class HeaderComponent < ViewComponent::Base
    attr_reader :title, :button_text, :button_path

    def initialize(title:, button_text: nil, button_path: nil)
      super()
      @title = title
      @button_text = button_text
      @button_path = button_path
    end
  end
end
