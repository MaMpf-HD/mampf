# Builds what the lecture home page says besides the registration rows: the one
# thing that is due first, the student's hand-ins and the counts in the staff
# blocks.
module LectureHomeHelper
  Focus = Struct.new(:kind, :subject, keyword_init: true)

  SHEET_STATES_TO_ACT_ON = [:nothing_handed_in, :grace_period, :tutor_decides].freeze
  NEWS_SHOWN = 3

  # Picks what the page leads with: an open campaign the student still has to
  # register in, else their next exam. Nothing when neither is there.
  def lecture_home_focus(campaigns:, next_exam:)
    campaign = Array(campaigns).find { |details| registration_needs_action?(details) }
    return Focus.new(kind: :campaign, subject: campaign) if campaign

    Focus.new(kind: :exam, subject: next_exam) if next_exam
  end

  # Whether the sheet due next still waits for the student.
  def lecture_home_sheet_due?(work)
    Array(work&.due).any? { |sheet| sheet.state.in?(SHEET_STATES_TO_ACT_ON) }
  end

  def lecture_home_sheet_deadline(sheet)
    t("lecture_home.work.due", deadline: format_date(sheet.assignment.deadline))
  end

  # The admission decision, where the lecture makes one; the points beside it
  # are the submissions page's own block.
  def lecture_home_admission(standing, certification)
    return unless standing.uses_exam_eligibility

    t("lecture_home.work.admission.#{certification&.status || "open"}")
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
