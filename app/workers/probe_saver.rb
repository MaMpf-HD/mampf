class ProbeSaver
  include Sidekiq::Worker

  def perform(quiz_id, question_id, correct, progress, attempt_token)
    probe = Probe.create(quiz_id: quiz_id,
                         question_id: question_id,
                         correct: correct,
                         progress: progress,
                         attempt_token: attempt_token)
    return unless progress == -1

    success = Probe.where(attempt_token: attempt_token, correct: true).count
    probe.update(success: success)
  end
end
