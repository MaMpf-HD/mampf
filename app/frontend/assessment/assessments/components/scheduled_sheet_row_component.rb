# A sheet the lecturer has set up with an exercise medium's release. The row
# says when it appears, and where its settings are: on the medium, since
# there is no sheet to edit yet.
class ScheduledSheetRowComponent < ViewComponent::Base
  attr_reader :sheet

  def initialize(sheet:)
    super()
    @sheet = sheet
  end

  def appears_on
    t("assessment.scheduled_sheet.appears_on",
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
