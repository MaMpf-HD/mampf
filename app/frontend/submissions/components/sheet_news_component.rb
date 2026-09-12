# Render the sheet-news element even without news: SubmissionsController
# needs its id as the target for Turbo Stream replacements.
class SheetNewsComponent < ViewComponent::Base
  # Three sheets name themselves; past that the rest are a count, because a
  # reader who has been away a month gets a sentence, not a paragraph.
  NAMED = 3

  attr_reader :lecture

  def initialize(sheets:, lecture:)
    super()
    @sheets = sheets
    @lecture = lecture
  end

  delegate :any?, to: :fresh

  def fresh
    @fresh ||= @sheets.select(&:news?)
  end

  def named
    fresh.first(NAMED)
  end

  def more_count
    fresh.size - named.size
  end

  # Turbo would answer a link to an anchor with a fresh copy of the page, and
  # that copy would land after the row's own report and put the marker back.
  # The browser's own jump does what is wanted here.
  def item(sheet)
    t("submission.hub.news.#{what_is_new(sheet)}_html",
      sheet: link_to(sheet.assignment.title, "##{dom_id(sheet.assignment, :sheet)}",
                     data: { turbo: false, action: "sheet-news#open" }))
  end

  private

    def what_is_new(sheet)
      return :both if sheet.new_correction? && sheet.new_points?

      sheet.new_correction? ? :correction : :points
    end
end
