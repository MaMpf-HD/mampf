# The history of a lecture's sheets, newest deadline first: one row each, the
# count, and the date the files go. What is still due is not in here - it has
# its own block above and would otherwise be told twice.
class SheetListComponent < ViewComponent::Base
  attr_reader :sheets, :lecture, :due

  delegate :any?, to: :sheets

  def initialize(sheets:, lecture:, due: [])
    super()
    @sheets = sheets
    @lecture = lecture
    @due = due
  end

  def count_label
    t("submission.hub.sheet_count", count: sheets.size)
  end

  # Before the first sheet has come back there is nothing to list, and saying
  # which sheet will land here first is more use than saying "none".
  def empty_message
    next_up = due.first
    return t("submission.hub.no_sheets_yet") unless next_up

    t("submission.hub.no_sheets_yet_named", sheet: next_up.assignment.title)
  end

  def deletion_notice
    return unless lecture.submission_deletion_date

    t("submission.hub.deletion_notice",
      date: l(lecture.submission_deletion_date, format: :long))
  end
end
