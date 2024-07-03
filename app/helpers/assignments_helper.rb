# Assignments Helper
module AssignmentsHelper
  def cancel_editing_assignment_path(assignment)
    return cancel_edit_assignment_path(assignment) if assignment.persisted?

    cancel_new_assignment_path(params: { lecture: assignment.lecture })
  end

  def file_button_text(assignment)
    return I18n.t("basics.file") unless assignment.accepted_file_type == ".pdf"

    I18n.t("basics.files")
  end
end
