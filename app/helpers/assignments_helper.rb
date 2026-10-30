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

  def test_week_label(assignment)
    week_label(assignment.test_period)
  end

  def test_period_heading(assignment)
    I18n.t("assessment.test.period", count: assignment.test_week_count)
  end

  # A new test is set to this week. Last week, offered for a test set up after
  # the fact, comes first in the list and would otherwise be the default.
  def test_week_options(assignment)
    choices = assignment.test_week_choices.map do |monday|
      [week_label(monday..(monday + 6)), monday.iso8601]
    end
    selected = assignment.test_week || Time.zone.today.beginning_of_week
    options_for_select(choices, selected.iso8601)
  end

  def test_week_count_options(assignment)
    choices = Assignment::TEST_WEEK_COUNTS.map do |count|
      [I18n.t("assessment.test.week_count_option", count: count), count]
    end
    options_for_select(choices, assignment.test_week_count)
  end

  def test_badge
    tag.span(I18n.t("assessment.test.badge"),
             class: "badge bg-secondary-subtle text-secondary-emphasis fw-normal ms-1")
  end

  private

    def week_label(week)
      I18n.t("assessment.test.week_label",
             from: I18n.l(week.first, format: :test_week_start),
             to: I18n.l(week.last, format: :test_week_end))
    end
end
