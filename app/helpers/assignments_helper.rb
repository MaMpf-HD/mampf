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
    week_label(assignment.test_week)
  end

  def test_week_options(assignment)
    choices = assignment.test_week_choices.map do |monday|
      [week_label(monday..(monday + 6)), monday.iso8601]
    end
    options_for_select(choices, assignment.deadline&.to_date&.beginning_of_week&.iso8601)
  end

  def week_label(week)
    I18n.t("assessment.test.week_label",
           from: I18n.l(week.first, format: :test_week_start),
           to: I18n.l(week.last, format: :test_week_end))
  end

  # The mark beside a test's title wherever it is listed among sheets.
  def test_badge
    tag.span(I18n.t("assessment.test.badge"),
             class: "badge bg-secondary-subtle text-secondary-emphasis fw-normal ms-1")
  end
end
