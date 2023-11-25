class ProbeSaver
  include Sidekiq::Worker

  # rubocop:todo Metrics/ParameterLists
  def perform(quiz_id, question_id, remark_id, correct, progress, session_id,
              study_participant, input)
    # rubocop:enable Metrics/ParameterLists
    probe = Probe.create(quiz_id:,
                         question_id:,
                         remark_id:,
                         correct:,
                         progress:,
                         session_id:,
                         study_participant:,
                         input:)
    return unless progress == -1

    success = Probe.where(session_id:, correct: true).count
    probe.update(success:)
  end
end
