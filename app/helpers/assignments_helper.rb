# Assignments Helper
module AssignmentsHelper
  def cancel_editing_assignment_path(assignment)
    return cancel_edit_assignment_path(assignment) if assignment.persisted?
    cancel_new_assignment_path(params: { lecture: assignment.lecture })
  end
end
