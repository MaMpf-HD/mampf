# Missing top-level docstring, please formulate one yourself 😁
class MemberListComponent < ViewComponent::Base
  renders_one :header_actions
  renders_one :columns
  renders_many :rows
  renders_one :footer

  def initialize(title:, count: nil, empty_message: nil)
    super()
    @title = title
    @count = count
    @empty_message = empty_message ||
                     I18n.t("roster.details.empty")
  end
end
