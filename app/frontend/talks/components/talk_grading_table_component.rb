class TalkGradingTableComponent < ViewComponent::Base
  def initialize(seminar:)
    super()
    @seminar = seminar
    @talks = seminar.talks.includes(:speakers, :assessment)
  end

  def gradable_talks
    @gradable_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.present? }
  end

  def legacy_talks
    @legacy_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.blank? }
  end

  def participations_by_talk
    @participations_by_talk ||= gradable_talks.index_with do |talk|
      talk.participations.includes(:user, :grader).index_by(&:user_id)
    end
  end

  def grading_enabled?
    Flipper.enabled?(:assessment_grading) && @assignment.assessable?
  end

  def tasks
    @assignment&.assessment&.persisted_tasks || []
  end

  def possible_statuses
    ["pending", "reviewed"]
  end
end
