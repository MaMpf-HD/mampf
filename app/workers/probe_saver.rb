class ProbeSaver
  include Sidekiq::Worker

  def perform(quiz_id, question_id, correct, progress, attempt_token)
    probe = Probe.create(quiz_id: quiz_id,
                         question_id: question_id,
                         correct: correct,
                         progress: progress,
                         attempt_token: attempt_token)
    return unless progress == -1

    # Lock all probes for this attempt to prevent race conditions
    # when calculating the final score.
    Probe.transaction do
      probes_for_attempt = Probe.where(attempt_token: attempt_token).lock(true)
      success = probes_for_attempt.where(correct: true).count
      probe.update(success: success)
    end
  end
end
