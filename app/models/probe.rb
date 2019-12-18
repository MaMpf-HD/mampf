class Probe < ApplicationRecord
  connects_to database: { writing: :interactions, reading: :interactions }

  def self.finished_quizzes(quiz_id)
    Probe.where(quiz_id: quiz_id, progress: -1).count
  end

  def self.success_in_quiz(quiz_id)
    success = Probe.where(quiz_id: quiz_id, progress: -1).pluck(:success)
                   .compact
    { median: success.percentile(50),
      lower_quartile: success.percentile(25),
      upper_quartile: success.percentile(75) }
  end
end
