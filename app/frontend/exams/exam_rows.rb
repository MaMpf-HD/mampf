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
end
