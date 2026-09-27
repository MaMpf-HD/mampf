# Render the sheet-news element even without news: SubmissionsController
# needs its id as the target for Turbo Stream replacements.
class SheetNewsComponent < ViewComponent::Base
  # Three sheets name themselves; past that the rest are a count, because a
  # reader who has been away a month gets a sentence, not a paragraph.
  NAMED = 3

  attr_reader :lecture

  # Away from the hub, as on the lecture home page, a sheet links to its row
  # on the hub instead of within the page.
  def initialize(sheets:, lecture:, on_hub: true)
    super()
    @sheets = sheets
    @lecture = lecture
    @on_hub = on_hub
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
    anchor = dom_id(sheet.assignment, :sheet)
    link = if @on_hub
      link_to(sheet.assignment.title, "##{anchor}",
              data: { turbo: false, action: "sheet-news#open" })
    else
      link_to(sheet.assignment.title, lecture_submissions_path(lecture, anchor: anchor),
              data: { turbo: false })
    end
    t("submission.hub.news.#{what_is_new(sheet)}_html", sheet: link)
  end

  private

    def what_is_new(sheet)
      return :both if sheet.new_correction? && sheet.new_points?

      sheet.new_correction? ? :correction : :points
    end
end
