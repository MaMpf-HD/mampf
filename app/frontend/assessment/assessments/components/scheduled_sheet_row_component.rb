# Renders a sheet that an exercise medium's release will make. Until then
# there is no sheet to edit, so the row points at the medium.
class ScheduledSheetRowComponent < ViewComponent::Base
  attr_reader :sheet

  def initialize(sheet:)
    super()
    @sheet = sheet
  end

  def appears_on
    t("assessment.scheduled_sheet.#{sheet.overdue? ? "overdue" : "appears_on"}",
      date: I18n.l(sheet.release_date, format: :short))
  end

  def medium_title
    sheet.medium.local_title_for_viewers
  end

  def deadline_display
    return unless sheet.deadline

    I18n.l(sheet.deadline, format: :short)
  end
end
