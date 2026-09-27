# The number beside an entry of a lecture's sidebar. It is rendered even at
# zero, only hidden, so that a Turbo Stream or the page's script finds it when
# the number changes without a reload.
class SidebarBadgeComponent < ViewComponent::Base
  HOME_ID = "sidebar-home-badge".freeze
  SUBMISSIONS_ID = "sidebar-submissions-badge".freeze

  def initialize(id:, count:, title:)
    super()
    @id = id
    @count = count
    @title = title
  end

  def call
    tag.span(@count, id: @id, class: "sidebar-item__badge", title: @title,
                     hidden: @count.zero?, data: { count: @count })
  end
end
