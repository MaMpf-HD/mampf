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

  # "20.–26.10.2026": the week a test is written in, wherever a sheet would
  # show its deadline.
  def test_week_label(assignment)
    week = assignment.test_week
    I18n.t("assessment.test.week_label",
           from: I18n.l(week.first, format: :test_week_start),
           to: I18n.l(week.last, format: :test_week_end))
  end
end
