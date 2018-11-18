# Administration Helper
module AdministrationHelper
  # Provide the list of courses together with information on whether or not
  # they can be edited by current user.
  # Used for dropdown menu in admin navbar.
  def editable_courses_dropdown
    editable = current_user.editable_courses_with_inheritance
                           .natural_sort_by(&:title)
    non_editable = (Course.all - editable).natural_sort_by(&:title)
    return editable if non_editable.blank?
    return non_editable if editable.blank?
    # Provide dropdown divider if both editable and non-editable courses are
    # present.
    editable + ['divider'] + non_editable
  end

  # Used for highlighting navs in admin navbar when corresponding controller
  # was called.
  def active_controller?(name, action = nil)
    active(controller_name == name && (action.blank? || action_name == action))
  end

  # Returns all courses that are not edited by the current user.
  def non_edited_courses
    Course.all - current_user.edited_courses
  end
end
