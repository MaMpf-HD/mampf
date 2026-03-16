class AssessmentBackfillWorker
  include Sidekiq::Worker

  def perform
    return unless ::Flipper.enabled?(:assessment_grading)

    Assignment.expired
              .where(deletion_date: Date.current..)
              .find_each do |assignment|
      backfill_assignment(assignment)
    end
  end

  private

    def backfill_assignment(assignment)
      assessment = assignment.assessment
      return unless assessment

      lecture = assignment.lecture
      memberships = TutorialMembership.joins(:tutorial)
                                      .where(tutorials: { lecture_id: lecture.id })

      return if memberships.none?

      tutorial_mapping = memberships.pluck(:user_id, :tutorial_id).to_h
      roster_user_ids = tutorial_mapping.keys

      assessment.seed_participations_from!(
        user_ids: roster_user_ids,
        tutorial_mapping: tutorial_mapping
      )
    end
end
