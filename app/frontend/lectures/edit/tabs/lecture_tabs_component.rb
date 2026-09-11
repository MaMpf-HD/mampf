class LectureTabsComponent < ViewComponent::Base
  renders_many :tabs, "TabComponent"

  def initialize(active_tab)
    super()
    @requested_tab = active_tab
  end

  # A name that matches no tab would leave every pane hidden, which reads as a
  # blank page - and the browser lays the hidden content out wrongly.
  def active_tab
    @active_tab ||=
      if tabs.any? { |tab| tab.name == @requested_tab }
        @requested_tab
      else
        "content"
      end
  end

  class TabComponent < ViewComponent::Base
    attr_reader :name, :label

    def initialize(name:, label:)
      super()
      @name = name
      @label = label
    end

    def call
      content
    end
  end
end
