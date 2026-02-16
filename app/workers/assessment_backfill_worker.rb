class AssessmentBackfillWorker
  include Sidekiq::Worker

  def perform
    return unless Flipper.enabled?(:assessment_grading)

    Assignment.expired.find_each do |assignment|
      backfill_assignment(assignment)
    end
  end

  private

    def backfill_assignment(assignment)
      assessment = assignment.assessment
      return unless assessment

      lecture = assignment.lecture
      memberships = TutorialMembership.where(
        tutorial_id: lecture.tutorial_ids
      )

      roster_count = memberships.count
      return if roster_count.zero?

      existing_count = assessment.assessment_participations.count
      return if existing_count >= roster_count

      tutorial_mapping = memberships.pluck(:user_id, :tutorial_id).to_h
      roster_user_ids = tutorial_mapping.keys

      assessment.seed_participations_from!(
        user_ids: roster_user_ids,
        tutorial_mapping: tutorial_mapping
      )
    end
end
