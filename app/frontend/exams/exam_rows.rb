# What both of an exam's tables draw: the candidates on the roster, by name,
# each with their participation.
module ExamRows
  STATUSES = [:reviewed, :pending_grading, :absent, :exempt].freeze

  def self.for(exam)
    candidates = exam.users.order(:name)
    Assessment::ParticipationIndex.build(candidates.map { |user| [exam.assessment, user] }).values
  end

  def self.status_options
    STATUSES.map { |status| [status.to_s, I18n.t("student_performance.records.columns.#{status}")] }
  end

  # A candidate is filtered by the tutorial they attend; the exam's
  # participation records none of its own.
  def self.tutorial_ids_by_user(exam)
    TutorialMembership.where(lecture_id: exam.lecture_id).pluck(:user_id, :tutorial_id).to_h
  end

  def self.tutorial_options(exam)
    tutorials = exam.lecture.tutorials.order(:title)
    return [] if tutorials.empty?

    tutorials.map { |tutorial| [tutorial.id.to_s, tutorial.title] } +
      [["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")]]
  end
end
