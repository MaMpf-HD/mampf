module AdministrationHelper
  def editable_courses_dropdown
    editable = current_user.editable_courses_with_inheritance.sort_by(&:title)
    non_editable = (Course.all - editable).sort_by(&:title)
    return editable if non_editable.blank?
    return non_editable if editable.blank?
    editable + ['divider'] + non_editable
  end
end
