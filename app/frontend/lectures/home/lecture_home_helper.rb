# Builds what the lecture home page says besides the registration rows: the one
# thing that is due first, the student's work in the lecture and the counts in
# the staff blocks.
module LectureHomeHelper
  Focus = Struct.new(:kind, :subject, keyword_init: true)

  SHEET_STATES_TO_ACT_ON = [:nothing_handed_in, :grace_period, :tutor_decides].freeze
  NEWS_SHOWN = 2

  # Picks what the page leads with: of an open campaign the student still has
  # to register in and a sheet they still have to hand in, whichever is due
  # first; otherwise their next exam. Nothing when nothing is due.
  def lecture_home_focus(campaigns:, work:, next_exam:)
    campaign = Array(campaigns).find { |details| registration_needs_action?(details) }
    sheet = work&.due&.find { |due| due.state.in?(SHEET_STATES_TO_ACT_ON) }
    candidates = []
    if campaign
      candidates << [campaign.campaign.registration_deadline,
                     Focus.new(kind: :campaign, subject: campaign)]
    end
    candidates << [sheet.assignment.deadline, Focus.new(kind: :sheet, subject: sheet)] if sheet
    return candidates.min_by(&:first).last if candidates.any?

    Focus.new(kind: :exam, subject: next_exam) if next_exam
  end

  # The sheets that are due next, unless the page leads with them already.
  def lecture_home_due_sheets(work, focus)
    sheets = Array(work&.due)
    return sheets unless focus&.kind == :sheet

    sheets - [focus.subject]
  end

  # Sheets with a correction or points the student has not looked at yet.
  def lecture_home_news_sheets(work)
    Array(work&.sheets).select(&:news?)
  end

  def lecture_home_sheet_deadline(sheet)
    t("lecture_home.work.due", deadline: format_date(sheet.assignment.deadline))
  end

  # One line for everything new, however many sheets came back since the
  # student last looked.
  def lecture_home_sheet_news(sheets)
    if sheets.one?
      key = sheets.first.new_correction? ? "new_correction" : "new_points"
      return t("lecture_home.work.#{key}", sheet: sheets.first.assignment.title)
    end

    titles = sheets.first(3).map { |sheet| sheet.assignment.title }
    titles << "…" if sheets.size > 3
    t("lecture_home.work.news_many", count: sheets.size, sheets: titles.join(", "))
  end

  # Points so far against what has been marked, as the submissions page counts
  # them, and the admission decision where the lecture makes one.
  def lecture_home_standing_line(standing, certification)
    parts = []
    if standing.points_total
      parts << t("lecture_home.work.points",
                 points: number_with_delimiter(standing.points_total),
                 max: number_with_delimiter(standing.points_marked_so_far))
    end
    if standing.uses_exam_eligibility
      parts << t("lecture_home.work.admission.#{certification&.status || "open"}")
    end
    parts.join(" · ").presence
  end

  def lecture_home_campaign_count_text(campaign, count)
    if campaign.completed?
      t("lecture_home.teacher.on_roster", count: count)
    elsif campaign.first_come_first_served?
      t("lecture_home.teacher.registered", count: count)
    else
      t("lecture_home.teacher.with_preferences", count: count)
    end
  end

  # Where the exam stands for the student: the list they are on, and the
  # admission when the lecture decides one.
  def lecture_home_exam_line(exam, certification)
    admission = certification && t("lecture_home.work.admission.#{certification.status}")
    [exam.date && format_date(exam.date), exam.location.presence, admission].compact.join(" · ")
  end
end
