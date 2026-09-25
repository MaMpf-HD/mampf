module LectureHomeHelper
  Focus = Struct.new(:kind, :subject, keyword_init: true)

  SHEET_STATES_TO_ACT_ON = [:nothing_handed_in, :grace_period, :tutor_decides].freeze
  NEWS_SHOWN = 3

  def lecture_home_focus(campaigns:, next_exam:)
    campaign = Array(campaigns).find { |details| registration_needs_action?(details) }
    return Focus.new(kind: :campaign, subject: campaign) if campaign

    Focus.new(kind: :exam, subject: next_exam) if next_exam
  end

  def lecture_home_sheet_due?(work)
    Array(work&.due).any? { |sheet| sheet.state.in?(SHEET_STATES_TO_ACT_ON) }
  end

  def lecture_home_sheet_deadline(sheet)
    t("lecture_home.work.due", deadline: format_date(sheet.assignment.deadline))
  end

  # The certification status, for a lecture that uses exam eligibility; no
  # certification yet reads as undecided.
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

  # Date, location and, where there is one, the certification status of an exam.
  def lecture_home_exam_line(exam, certification)
    admission = certification && t("lecture_home.work.admission.#{certification.status}")
    [exam.date && format_date(exam.date), exam.location.presence, admission].compact.join(" · ")
  end
end
