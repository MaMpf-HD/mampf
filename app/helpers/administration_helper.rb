# Administration Helper
module AdministrationHelper
  # Used for highlighting navs in admin navbar when corresponding controller
  # was called.
  def active_controller?(name, action = nil)
    active(controller_name == name && (action.blank? || action_name == action))
  end
end
