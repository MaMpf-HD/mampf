class ProbeSaver
  include Sidekiq::Worker

  def perform(quiz_id, question_id, remark_id, correct, progress, session_id,
              study_participant, input)
    probe = Probe.create(quiz_id: quiz_id,
                         question_id: question_id,
                         remark_id: remark_id,
                         correct: correct,
                         progress: progress,
                         session_id: session_id,
                         study_participant: study_participant,
                         input: input)
    return unless progress == -1

    success = Probe.where(session_id: session_id, correct: true).count
    probe.update(success: success)
  end
end
