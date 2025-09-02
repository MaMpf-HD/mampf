class LectureTabsComponent < ViewComponent::Base
  renders_many :tabs, "TabComponent"

  def initialize(active_tab, is_vignette_lecture)
    super()
    @active_tab = active_tab
    @is_vignette_lecture = is_vignette_lecture
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
